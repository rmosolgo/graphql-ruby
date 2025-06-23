# frozen_string_literal: true
require "graphql/execution/interpreter/runtime/graphql_result"

#####
# Next thoughts
#
# - `continue_field` is probably a step of its own -- that method can somehow be factored out
# - It seems like Dataloader/Lazy will fit in at the queue level, so the flow would be:
#   - Run jobs from queue
#   - Then, run dataloader/lazies
#   - Repeat
module GraphQL
  module Execution
    class Interpreter
      # I think it would be even better if we could somehow make
      # `continue_field` not recursive. "Trampolining" it somehow.
      #
      # @api private
      class Runtime
        class CurrentState
          def initialize
            @current_field = nil
            @current_arguments = nil
            @current_result_name = nil
            @current_result = nil
            @was_authorized_by_scope_items = nil
          end

          def current_object
            @current_result.graphql_application_value
          end

          attr_accessor :current_result, :current_result_name,
            :current_arguments, :current_field, :was_authorized_by_scope_items
        end

        class RunQueue
          def initialize(dataloader:, lazies_at_depth:)
            @next_flush = []
            @dataloader = dataloader
            @lazies_at_depth = lazies_at_depth
            @running_eagerly = false
          end

          def <<(step)
            if @running_eagerly
              step.run
            else
              @next_flush << step
            end
          end

          def complete(eager: false)
            prev_eagerly = @running_eagerly
            @running_eagerly = eager
            while (fl = @next_flush) && !fl.empty?
              @next_flush = []
              while (step = fl.shift)
                step.run
              end
              Interpreter::Resolve.resolve_each_depth(@lazies_at_depth, @dataloader)
            end
          ensure
            @running_eagerly = prev_eagerly
          end
        end

        # @return [GraphQL::Query]
        attr_reader :query

        # @return [Class<GraphQL::Schema>]
        attr_reader :schema

        # @return [GraphQL::Query::Context]
        attr_reader :context

        attr_reader :dataloader, :run_queue

        def initialize(query:, lazies_at_depth:)
          @query = query
          @current_trace = query.current_trace
          @dataloader = query.multiplex.dataloader
          @lazies_at_depth = lazies_at_depth
          @schema = query.schema
          @context = query.context
          @response = nil
          # Identify runtime directives by checking which of this schema's directives have overridden `def self.resolve`
          @runtime_directive_names = []
          noop_resolve_owner = GraphQL::Schema::Directive.singleton_class
          @schema_directives = schema.directives
          @schema_directives.each do |name, dir_defn|
            if dir_defn.method(:resolve).owner != noop_resolve_owner
              @runtime_directive_names << name
            end
          end
          # { Class => Boolean }
          @lazy_cache = {}.compare_by_identity
          @run_queue = RunQueue.new(dataloader: @dataloader, lazies_at_depth: @lazies_at_depth)
        end

        def final_result
          @run_queue.complete
          @response.respond_to?(:graphql_result_data) ? @response.graphql_result_data : @response
        end

        def inspect
          "#<#{self.class.name} response=#{@response.inspect}>"
        end

        class DirectivesStep
          def initialize(runtime, object, ast_node, next_step)
            @runtime = runtime
            @object = object
            @ast_node = ast_node
            @next_step = next_step
          end

          def run
            @runtime.call_method_on_directives(:resolve, @object, @ast_node.directives) do
              @runtime.run_queue << @next_step
            end
          end
        end

        class ResolveTypeStep
          def initialize(runtime, response_hash, was_scoped)
            @runtime = runtime
            @response_hash = response_hash
            @was_scoped = was_scoped
          end

          def run
            current_type = @response_hash.graphql_result_type
            value = @response_hash.graphql_application_value
            resolved_type_result = begin
              @runtime.resolve_type(current_type, value)
            rescue GraphQL::ExecutionError, GraphQL::UnauthorizedError => ex_err
              return @runtime.continue_value(ex_err, @response_hash.graphql_field, @response_hash.graphql_is_non_null_in_parent, @response_hash.ast_node, @response_hash.graphql_result_name, @response_hash.graphql_parent)
            rescue StandardError => err
              begin
                @runtime.query.handle_or_reraise(err)
              rescue GraphQL::ExecutionError => ex_err
                return @runtime.continue_value(ex_err, @response_hash.graphql_field, @response_hash.graphql_is_non_null_in_parent, @response_hash.ast_node, @response_hash.graphql_result_name, @response_hash.graphql_parent)
              end
            end

            # after_lazy(resolved_type_or_lazy, ast_node: ast_node, field: field, owner_object: owner_object, arguments: arguments, trace: false, result_name: result_name, result: selection_result, runtime_state: runtime_state) do |resolved_type_result, runtime_state|
            if resolved_type_result.is_a?(Array) && resolved_type_result.length == 2
              resolved_type, resolved_value = resolved_type_result
            else
              resolved_type = resolved_type_result
              resolved_value = value
            end

            possible_types = @runtime.query.types.possible_types(current_type)
            if !possible_types.include?(resolved_type)
              field = @response_hash.graphql_field
              parent_type = field.owner_type
              err_class = current_type::UnresolvedTypeError
              type_error = err_class.new(resolved_value, field, parent_type, resolved_type, possible_types)
              @runtime.schema.type_error(type_error, @runtime.context)
              @runtime.set_result(selection_result, result_name, nil, false, is_non_null)
              nil
            else
              @runtime.continue_field(resolved_value, @response_hash.graphql_field, resolved_type, @response_hash.ast_node, @response_hash.graphql_selections, @response_hash.graphql_is_non_null_in_parent, @response_hash.graphql_arguments, @response_hash.graphql_result_name, @response_hash.graphql_parent, @was_scoped, @runtime_state)
            end
          end
        end

        # @return [void]
        def run_eager
          root_type = query.root_type
          case query
          when GraphQL::Query
            ast_node = query.selected_operation
            selections = ast_node.selections
            object = query.root_value
            is_eager = ast_node.operation_type == "mutation"
            base_path = nil
          when GraphQL::Query::Partial
            ast_node = query.ast_nodes.first
            selections = query.ast_nodes.map(&:selections).inject(&:+)
            object = query.object
            is_eager = false
            base_path = query.path
          else
            raise ArgumentError, "Unexpected Runnable, can't execute: #{query.class} (#{query.inspect})"
          end
          object = schema.sync_lazy(object) # TODO test query partial with lazy root object
          runtime_state = get_current_runtime_state
          case root_type.kind.name
          when "OBJECT"
            object_proxy = root_type.wrap(object, context)
            object_proxy = schema.sync_lazy(object_proxy)
            if object_proxy.nil?
              @response = nil
            else
              @response = GraphQLResultHash.new(self, nil, root_type, object_proxy, nil, false, selections, is_eager, ast_node, nil, nil)
              @response.base_path = base_path
              runtime_state.current_result = @response
              if !ast_node.directives.empty?
                dir_step = DirectivesStep.new(self, object, ast_node, obj_step)
                @run_queue << dir_step
              else
                @run_queue << @response
              end
            end
          when "LIST"
            inner_type = root_type.unwrap
            case inner_type.kind.name
            when "SCALAR", "ENUM"
              result_name = ast_node.alias || ast_node.name
              field_defn = query.field_definition
              owner_type = field_defn.owner
              selection_result = GraphQLResultHash.new(nil, owner_type, nil, nil, false, EmptyObjects::EMPTY_ARRAY, false, ast_node, nil, nil)
              selection_result.base_path = base_path
              selection_result.ordered_result_keys = [result_name]
              runtime_state.current_result = selection_result
              runtime_state.current_result_name = result_name
              continue_value = continue_value(object, field_defn, false, ast_node, result_name, selection_result)
              if HALT != continue_value
                continue_field(continue_value, field_defn, root_type, ast_node, nil, false, nil, result_name, selection_result, false, runtime_state) # rubocop:disable Metrics/ParameterLists
              end
              @response = selection_result[result_name]
            else
              @response = GraphQLResultArray.new(self, nil, root_type, object, nil, false, selections, false, ast_node, nil, nil)
              @response.base_path = base_path
              @run_queue << @response
            end
          when "SCALAR", "ENUM"
            result_name = ast_node.alias || ast_node.name
            field_defn = query.field_definition
            owner_type = field_defn.owner
            selection_result = GraphQLResultHash.new(nil, owner_type, nil, nil, false, EmptyObjects::EMPTY_ARRAY, false, ast_node, nil, nil)
            selection_result.ordered_result_keys = [result_name]
            selection_result.base_path = base_path
            runtime_state = get_current_runtime_state
            runtime_state.current_result = selection_result
            runtime_state.current_result_name = result_name
            continue_value = continue_value(object, field_defn, false, ast_node, result_name, selection_result)
            if HALT != continue_value
              continue_field(continue_value, field_defn, query.root_type, ast_node, nil, false, nil, result_name, selection_result, false, runtime_state) # rubocop:disable Metrics/ParameterLists
            end
            @response = selection_result[result_name]
          when "UNION", "INTERFACE"

            @response = GraphQLResultHash.new(nil, root_type, object, nil, false, selections, false, query.ast_nodes.first, nil, nil)
            @response.base_path = base_path

            @run_queue << ResolveTypeStep.new(self, @response, false)
          else
            raise "Invariant: unsupported type kind for partial execution: #{root_type.kind.inspect} (#{root_type})"
          end
          @run_queue.complete
          nil
        end

        def each_gathered_selections(response_hash)
          ordered_result_keys = []
          gathered_selections = gather_selections(response_hash.graphql_application_value, response_hash.graphql_result_type, response_hash.graphql_selections, nil, {}, ordered_result_keys)
          ordered_result_keys.uniq!
          if gathered_selections.is_a?(Array)
            gathered_selections.each do |item|
              yield(item, true, ordered_result_keys)
            end
          else
            yield(gathered_selections, false, ordered_result_keys)
          end
        end

        def gather_selections(owner_object, owner_type, selections, selections_to_run, selections_by_name, ordered_result_keys)
          selections.each do |node|
            # Skip gathering this if the directive says so
            if !directives_include?(node, owner_object, owner_type)
              next
            end

            if node.is_a?(GraphQL::Language::Nodes::Field)
              response_key = node.alias || node.name
              ordered_result_keys << response_key
              selections = selections_by_name[response_key]
              # if there was already a selection of this field,
              # use an array to hold all selections,
              # otherwise, use the single node to represent the selection
              if selections
                # This field was already selected at least once,
                # add this node to the list of selections
                s = Array(selections)
                s << node
                selections_by_name[response_key] = s
              else
                # No selection was found for this field yet
                selections_by_name[response_key] = node
              end
            else
              # This is an InlineFragment or a FragmentSpread
              if !@runtime_directive_names.empty? && node.directives.any? { |d| @runtime_directive_names.include?(d.name) }
                next_selections = {}
                next_selections[:graphql_directives] = node.directives
                if selections_to_run
                  selections_to_run << next_selections
                else
                  selections_to_run = []
                  selections_to_run << selections_by_name
                  selections_to_run << next_selections
                end
              else
                next_selections = selections_by_name
              end

              case node
              when GraphQL::Language::Nodes::InlineFragment
                if node.type
                  type_defn = query.types.type(node.type.name)

                  if query.types.possible_types(type_defn).include?(owner_type)
                    result = gather_selections(owner_object, owner_type, node.selections, selections_to_run, next_selections, ordered_result_keys)
                    if !result.equal?(next_selections)
                      selections_to_run = result
                    end
                  end
                else
                  # it's an untyped fragment, definitely continue
                  result = gather_selections(owner_object, owner_type, node.selections, selections_to_run, next_selections, ordered_result_keys)
                  if !result.equal?(next_selections)
                    selections_to_run = result
                  end
                end
              when GraphQL::Language::Nodes::FragmentSpread
                fragment_def = query.fragments[node.name]
                type_defn = query.types.type(fragment_def.type.name)
                if query.types.possible_types(type_defn).include?(owner_type)
                  result = gather_selections(owner_object, owner_type, fragment_def.selections, selections_to_run, next_selections, ordered_result_keys)
                  if !result.equal?(next_selections)
                    selections_to_run = result
                  end
                end
              else
                raise "Invariant: unexpected selection class: #{node.class}"
              end
            end
          end
          selections_to_run || selections_by_name
        end

        NO_ARGS = GraphQL::EmptyObjects::EMPTY_HASH

        # @return [void]
        def evaluate_selections(gathered_selections, selections_result, target_result, runtime_state) # rubocop:disable Metrics/ParameterLists

        end

        # @return [void]
        def evaluate_selection(result_name, field_ast_nodes_or_ast_node, selections_result) # rubocop:disable Metrics/ParameterLists
          return if selections_result.graphql_dead
          # As a performance optimization, the hash key will be a `Node` if
          # there's only one selection of the field. But if there are multiple
          # selections of the field, it will be an Array of nodes
          if field_ast_nodes_or_ast_node.is_a?(Array)
            field_ast_nodes = field_ast_nodes_or_ast_node
            ast_node = field_ast_nodes.first
          else
            field_ast_nodes = nil
            ast_node = field_ast_nodes_or_ast_node
          end
          field_name = ast_node.name
          owner_type = selections_result.graphql_result_type
          field_defn = query.types.field(owner_type, field_name)

          # Set this before calling `run_with_directives`, so that the directive can have the latest path
          runtime_state = get_current_runtime_state
          runtime_state.current_field = field_defn
          runtime_state.current_result = selections_result
          runtime_state.current_result_name = result_name

          owner_object = selections_result.graphql_application_value
          if field_defn.dynamic_introspection
            owner_object = field_defn.owner.wrap(owner_object, context)
          end

          if !field_defn.any_arguments?
            resolved_arguments = GraphQL::Execution::Interpreter::Arguments::EMPTY
            if field_defn.extras.size == 0
              evaluate_selection_with_resolved_keyword_args(
                NO_ARGS, resolved_arguments, field_defn, ast_node, field_ast_nodes, owner_object, result_name, selections_result, runtime_state
              )
            else
              evaluate_selection_with_args(resolved_arguments, field_defn, ast_node, field_ast_nodes, owner_object, result_name, selections_result, runtime_state)
            end
          else
            @query.arguments_cache.dataload_for(ast_node, field_defn, owner_object) do |resolved_arguments|
              runtime_state = get_current_runtime_state # This might be in a different fiber
              evaluate_selection_with_args(resolved_arguments, field_defn, ast_node, field_ast_nodes, owner_object, result_name, selections_result, runtime_state)
            end
          end
        end

        def evaluate_selection_with_args(arguments, field_defn, ast_node, field_ast_nodes, object, result_name, selection_result, runtime_state)  # rubocop:disable Metrics/ParameterLists
          after_lazy(arguments, field: field_defn, ast_node: ast_node, owner_object: object, arguments: arguments, result_name: result_name, result: selection_result, runtime_state: runtime_state) do |resolved_arguments, runtime_state|
            if resolved_arguments.is_a?(GraphQL::ExecutionError) || resolved_arguments.is_a?(GraphQL::UnauthorizedError)
              return_type_non_null = field_defn.type.non_null?
              continue_value(resolved_arguments, field_defn, return_type_non_null, ast_node, result_name, selection_result)
              next
            end

            kwarg_arguments = if field_defn.extras.empty?
              if resolved_arguments.empty?
                # We can avoid allocating the `{ Symbol => Object }` hash in this case
                NO_ARGS
              else
                resolved_arguments.keyword_arguments
              end
            else
              # Bundle up the extras, then make a new arguments instance
              # that includes the extras, too.
              extra_args = {}
              field_defn.extras.each do |extra|
                case extra
                when :ast_node
                  extra_args[:ast_node] = ast_node
                when :execution_errors
                  extra_args[:execution_errors] = ExecutionErrors.new(context, ast_node, current_path)
                when :path
                  extra_args[:path] = current_path
                when :lookahead
                  if !field_ast_nodes
                    field_ast_nodes = [ast_node]
                  end

                  extra_args[:lookahead] = Execution::Lookahead.new(
                    query: query,
                    ast_nodes: field_ast_nodes,
                    field: field_defn,
                  )
                when :argument_details
                  # Use this flag to tell Interpreter::Arguments to add itself
                  # to the keyword args hash _before_ freezing everything.
                  extra_args[:argument_details] = :__arguments_add_self
                when :parent
                  parent_result = selection_result.graphql_parent
                  if parent_result.is_a?(GraphQL::Execution::Interpreter::Runtime::GraphQLResultArray)
                    parent_result = parent_result.graphql_parent
                  end
                  parent_value = parent_result&.graphql_application_value&.object
                  extra_args[:parent] = parent_value
                else
                  extra_args[extra] = field_defn.fetch_extra(extra, context)
                end
              end
              if !extra_args.empty?
                resolved_arguments = resolved_arguments.merge_extras(extra_args)
              end
              resolved_arguments.keyword_arguments
            end

            evaluate_selection_with_resolved_keyword_args(kwarg_arguments, resolved_arguments, field_defn, ast_node, field_ast_nodes, object, result_name, selection_result, runtime_state)
          end
        end

        def evaluate_selection_with_resolved_keyword_args(kwarg_arguments, resolved_arguments, field_defn, ast_node, field_ast_nodes, object, result_name, selection_result, runtime_state)  # rubocop:disable Metrics/ParameterLists
          runtime_state.current_field = field_defn
          runtime_state.current_arguments = resolved_arguments
          runtime_state.current_result_name = result_name
          runtime_state.current_result = selection_result
          # Optimize for the case that field is selected only once
          if field_ast_nodes.nil? || field_ast_nodes.size == 1
            next_selections = ast_node.selections
            directives = ast_node.directives
          else
            next_selections = []
            directives = []
            field_ast_nodes.each { |f|
              next_selections.concat(f.selections)
              directives.concat(f.directives)
            }
          end

          field_result = call_method_on_directives(:resolve, object, directives) do
            if !directives.empty?
              # This might be executed in a different context; reset this info
              runtime_state = get_current_runtime_state
              runtime_state.current_field = field_defn
              runtime_state.current_arguments = resolved_arguments
              runtime_state.current_result_name = result_name
              runtime_state.current_result = selection_result
            end
            # Actually call the field resolver and capture the result
            app_result = begin
              @current_trace.begin_execute_field(field_defn, object, kwarg_arguments, query)
              @current_trace.execute_field(field: field_defn, ast_node: ast_node, query: query, object: object, arguments: kwarg_arguments) do
                field_defn.resolve(object, kwarg_arguments, context)
              end
            rescue GraphQL::ExecutionError => err
              err
            rescue StandardError => err
              begin
                query.handle_or_reraise(err)
              rescue GraphQL::ExecutionError => ex_err
                ex_err
              end
            end
            @current_trace.end_execute_field(field_defn, object, kwarg_arguments, query, app_result)
            after_lazy(app_result, field: field_defn, ast_node: ast_node, owner_object: object, arguments: resolved_arguments, result_name: result_name, result: selection_result, runtime_state: runtime_state) do |inner_result, runtime_state|
              return_type = field_defn.type
              continue_value = continue_value(inner_result, field_defn, return_type.non_null?, ast_node, result_name, selection_result)
              if HALT != continue_value
                was_scoped = runtime_state.was_authorized_by_scope_items
                runtime_state.was_authorized_by_scope_items = nil
                continue_field(continue_value, field_defn, return_type, ast_node, next_selections, false, resolved_arguments, result_name, selection_result, was_scoped, runtime_state)
              else
                nil
              end
            end
          end
          # If this field is a root mutation field, immediately resolve
          # all of its child fields before moving on to the next root mutation field.
          # (Subselections of this mutation will still be resolved level-by-level.)
          if selection_result.graphql_is_eager
            Interpreter::Resolve.resolve_all([field_result], @dataloader)
          end
        end

        def set_result(selection_result, result_name, value, is_child_result, is_non_null)
          if !selection_result.graphql_dead
            if value.nil? && is_non_null
              # This is an invalid nil that should be propagated
              # One caller of this method passes a block,
              # namely when application code returns a `nil` to GraphQL and it doesn't belong there.
              # The other possibility for reaching here is when a field returns an ExecutionError, so we write
              # `nil` to the response, not knowing whether it's an invalid `nil` or not.
              # (And in that case, we don't have to call the schema's handler, since it's not a bug in the application.)
              # TODO the code is trying to tell me something.
              yield if block_given?
              parent = selection_result.graphql_parent
              if parent.nil? # This is a top-level result hash
                @response = nil
              else
                name_in_parent = selection_result.graphql_result_name
                is_non_null_in_parent = selection_result.graphql_is_non_null_in_parent
                set_result(parent, name_in_parent, nil, false, is_non_null_in_parent)
                set_graphql_dead(selection_result)
              end
            elsif is_child_result
              selection_result.set_child_result(result_name, value)
            else
              selection_result.set_leaf(result_name, value)
            end
          end
        end

        # Mark this node and any already-registered children as dead,
        # so that it accepts no more writes.
        def set_graphql_dead(selection_result)
          case selection_result
          when GraphQLResultArray
            selection_result.graphql_dead = true
            selection_result.values.each { |v| set_graphql_dead(v) }
          when GraphQLResultHash
            selection_result.graphql_dead = true
            selection_result.each { |k, v| set_graphql_dead(v) }
          else
            # It's a scalar, no way to mark it dead.
          end
        end

        def current_path
          st = get_current_runtime_state
          result = st.current_result
          path = result && result.path
          if path && (rn = st.current_result_name)
            path = path.dup
            path.push(rn)
          end
          path
        end

        HALT = Object.new.freeze
        def continue_value(value, field, is_non_null, ast_node, result_name, selection_result) # rubocop:disable Metrics/ParameterLists
          case value
          when nil
            if is_non_null
              set_result(selection_result, result_name, nil, false, is_non_null) do
                # When this comes from a list item, use the parent object:
                is_from_array = selection_result.is_a?(GraphQLResultArray)
                parent_type = is_from_array ? selection_result.graphql_parent.graphql_result_type : selection_result.graphql_result_type
                # This block is called if `result_name` is not dead. (Maybe a previous invalid nil caused it be marked dead.)
                err = parent_type::InvalidNullError.new(parent_type, field, ast_node, is_from_array: is_from_array)
                schema.type_error(err, context)
              end
            else
              set_result(selection_result, result_name, nil, false, is_non_null)
            end
            HALT
          when GraphQL::Error
            # Handle these cases inside a single `when`
            # to avoid the overhead of checking three different classes
            # every time.
            if value.is_a?(GraphQL::ExecutionError)
              if selection_result.nil? || !selection_result.graphql_dead
                value.path ||= current_path
                value.ast_node ||= ast_node
                context.errors << value
                if selection_result
                  set_result(selection_result, result_name, nil, false, is_non_null)
                end
              end
              HALT
            elsif value.is_a?(GraphQL::UnauthorizedFieldError)
              value.field ||= field
              # this hook might raise & crash, or it might return
              # a replacement value
              next_value = begin
                schema.unauthorized_field(value)
              rescue GraphQL::ExecutionError => err
                err
              end
              continue_value(next_value, field, is_non_null, ast_node, result_name, selection_result)
            elsif value.is_a?(GraphQL::UnauthorizedError)
              # this hook might raise & crash, or it might return
              # a replacement value
              next_value = begin
                schema.unauthorized_object(value)
              rescue GraphQL::ExecutionError => err
                err
              end
              continue_value(next_value, field, is_non_null, ast_node, result_name, selection_result)
            elsif GraphQL::Execution::SKIP == value
              # It's possible a lazy was already written here
              case selection_result
              when GraphQLResultHash
                selection_result.delete(result_name)
              when GraphQLResultArray
                selection_result.graphql_skip_at(result_name)
              when nil
                # this can happen with directives
              else
                raise "Invariant: unexpected result class #{selection_result.class} (#{selection_result.inspect})"
              end
              HALT
            else
              # What could this actually _be_? Anyhow,
              # preserve the default behavior of doing nothing with it.
              value
            end
          when Array
            # It's an array full of execution errors; add them all.
            if !value.empty? && value.all?(GraphQL::ExecutionError)
              list_type_at_all = (field && (field.type.list?))
              if selection_result.nil? || !selection_result.graphql_dead
                value.each_with_index do |error, index|
                  error.ast_node ||= ast_node
                  error.path ||= current_path + (list_type_at_all ? [index] : [])
                  context.errors << error
                end
                if selection_result
                  if list_type_at_all
                    result_without_errors = value.map { |v| v.is_a?(GraphQL::ExecutionError) ? nil : v }
                    set_result(selection_result, result_name, result_without_errors, false, is_non_null)
                  else
                    set_result(selection_result, result_name, nil, false, is_non_null)
                  end
                end
              end
              HALT
            else
              value
            end
          when GraphQL::Execution::Interpreter::RawValue
            # Write raw value directly to the response without resolving nested objects
            set_result(selection_result, result_name, value.resolve, false, is_non_null)
            HALT
          else
            value
          end
        end

        # The resolver for `field` returned `value`. Continue to execute the query,
        # treating `value` as `type` (probably the return type of the field).
        #
        # Use `next_selections` to resolve object fields, if there are any.
        #
        # Location information from `path` and `ast_node`.
        #
        # @return [Lazy, Array, Hash, Object] Lazy, Array, and Hash are all traversed to resolve lazy values later
        def continue_field(value, field, current_type, ast_node, next_selections, is_non_null, arguments, result_name, selection_result, was_scoped, runtime_state) # rubocop:disable Metrics/ParameterLists
          if current_type.non_null?
            current_type = current_type.of_type
            is_non_null = true
          end

          case current_type.kind.name
          when "SCALAR", "ENUM"
            r = begin
              current_type.coerce_result(value, context)
            rescue GraphQL::ExecutionError => ex_err
              return continue_value(ex_err, field, is_non_null, ast_node, result_name, selection_result)
            rescue StandardError => err
              query.handle_or_reraise(err)
            end
            set_result(selection_result, result_name, r, false, is_non_null)
            r
          when "UNION", "INTERFACE"
            response_hash = GraphQLResultHash.new(self, result_name, current_type, value, selection_result, is_non_null, next_selections, false, ast_node, arguments, field)
            @run_queue << ResolveTypeStep.new(self, response_hash, was_scoped)
          when "OBJECT"
            object_proxy = begin
              was_scoped ? current_type.wrap_scoped(value, context) : current_type.wrap(value, context)
            rescue GraphQL::ExecutionError => err
              err
            end
            after_lazy(object_proxy, ast_node: ast_node, field: field, owner_object: selection_result.graphql_application_value, arguments: arguments, trace: false, result_name: result_name, result: selection_result, runtime_state: runtime_state) do |inner_object, runtime_state|
              continue_value = continue_value(inner_object, field, is_non_null, ast_node, result_name, selection_result)
              if HALT != continue_value
                response_hash = GraphQLResultHash.new(self, result_name, current_type, continue_value, selection_result, is_non_null, next_selections, false, ast_node, arguments, field)
                set_result(selection_result, result_name, response_hash, true, is_non_null)
                @run_queue << response_hash
              end
            end
          when "LIST"
            response_list = GraphQLResultArray.new(self, result_name, current_type, value, selection_result, is_non_null, next_selections, false, ast_node, arguments, field)
            set_result(selection_result, result_name, response_list, true, is_non_null)
            @run_queue << response_list
          else
            raise "Invariant: Unhandled type kind #{current_type.kind} (#{current_type})"
          end
        end

        def resolve_list_item(inner_value, inner_type, inner_type_non_null, ast_node, field, owner_object, arguments, this_idx, response_list, was_scoped, runtime_state) # rubocop:disable Metrics/ParameterLists
          runtime_state.current_result_name = this_idx
          runtime_state.current_result = response_list
          call_method_on_directives(:resolve_each, owner_object, ast_node.directives) do
            # This will update `response_list` with the lazy
            after_lazy(inner_value, ast_node: ast_node, field: field, owner_object: owner_object, arguments: arguments, result_name: this_idx, result: response_list, runtime_state: runtime_state) do |inner_inner_value, runtime_state|
              continue_value = continue_value(inner_inner_value, field, inner_type_non_null, ast_node, this_idx, response_list)
              if HALT != continue_value
                continue_field(continue_value, field, inner_type, ast_node, response_list.graphql_selections, false, arguments, this_idx, response_list, was_scoped, runtime_state)
              end
            end
          end
        end

        def call_method_on_directives(method_name, object, directives, &block)
          return yield if directives.nil? || directives.empty?
          run_directive(method_name, object, directives, 0, &block)
        end

        def run_directive(method_name, object, directives, idx, &block)
          dir_node = directives[idx]
          if !dir_node
            yield
          else
            dir_defn = @schema_directives.fetch(dir_node.name)
            raw_dir_args = arguments(nil, dir_defn, dir_node)
            if !raw_dir_args.is_a?(GraphQL::ExecutionError)
              begin
                dir_defn.validate!(raw_dir_args, context)
              rescue GraphQL::ExecutionError => err
                raw_dir_args = err
              end
            end
            dir_args = continue_value(
              raw_dir_args, # value
              nil, # field
              false, # is_non_null
              dir_node, # ast_node
              nil, # result_name
              nil, # selection_result
            )

            if dir_args == HALT
              nil
            else
              dir_defn.public_send(method_name, object, dir_args, context) do
                run_directive(method_name, object, directives, idx + 1, &block)
              end
            end
          end
        end

        # Check {Schema::Directive.include?} for each directive that's present
        def directives_include?(node, graphql_object, parent_type)
          node.directives.each do |dir_node|
            dir_defn = @schema_directives.fetch(dir_node.name)
            args = arguments(graphql_object, dir_defn, dir_node)
            if !dir_defn.include?(graphql_object, args, context)
              return false
            end
          end
          true
        end

        def get_current_runtime_state
          current_state = Fiber[:__graphql_runtime_info] ||= {}.compare_by_identity
          current_state[@query] ||= CurrentState.new
        end

        def minimal_after_lazy(value, &block)
          if lazy?(value)
            GraphQL::Execution::Lazy.new do
              result = @schema.sync_lazy(value)
              # The returned result might also be lazy, so check it, too
              minimal_after_lazy(result, &block)
            end
          else
            yield(value)
          end
        end

        # @param obj [Object] Some user-returned value that may want to be batched
        # @param field [GraphQL::Schema::Field]
        # @param eager [Boolean] Set to `true` for mutation root fields only
        # @param trace [Boolean] If `false`, don't wrap this with field tracing
        # @return [GraphQL::Execution::Lazy, Object] If loading `object` will be deferred, it's a wrapper over it.
        def after_lazy(lazy_obj, field:, owner_object:, arguments:, ast_node:, result:, result_name:, eager: false, runtime_state:, trace: true, &block)
          if lazy?(lazy_obj)
            orig_result = result
            was_authorized_by_scope_items = runtime_state.was_authorized_by_scope_items
            lazy = GraphQL::Execution::Lazy.new(field: field) do
              # This block might be called in a new fiber;
              # In that case, this will initialize a new state
              # to avoid conflicting with the parent fiber.
              runtime_state = get_current_runtime_state
              runtime_state.current_field = field
              runtime_state.current_arguments = arguments
              runtime_state.current_result_name = result_name
              runtime_state.current_result = orig_result
              runtime_state.was_authorized_by_scope_items = was_authorized_by_scope_items
              # Wrap the execution of _this_ method with tracing,
              # but don't wrap the continuation below
              result = nil
              inner_obj = begin
                result = if trace
                  @current_trace.begin_execute_field(field, owner_object, arguments, query)
                  @current_trace.execute_field_lazy(field: field, query: query, object: owner_object, arguments: arguments, ast_node: ast_node) do
                    schema.sync_lazy(lazy_obj)
                  end
                else
                  schema.sync_lazy(lazy_obj)
                end
              rescue GraphQL::ExecutionError, GraphQL::UnauthorizedError => ex_err
                ex_err
              rescue StandardError => err
                begin
                  query.handle_or_reraise(err)
                rescue GraphQL::ExecutionError => ex_err
                  ex_err
                end
              ensure
                if trace
                  @current_trace.end_execute_field(field, owner_object, arguments, query, result)
                end
              end
              yield(inner_obj, runtime_state)
            end

            if eager
              lazy.value
            else
              set_result(result, result_name, lazy, false, false) # is_non_null is irrelevant here
              current_depth = 0
              while result
                current_depth += 1
                result = result.graphql_parent
              end
              @lazies_at_depth[current_depth] << lazy
              lazy
            end
          else
            # Don't need to reset state here because it _wasn't_ lazy.
            yield(lazy_obj, runtime_state)
          end
        end

        def arguments(graphql_object, arg_owner, ast_node)
          if arg_owner.arguments_statically_coercible?
            query.arguments_for(ast_node, arg_owner)
          else
            # The arguments must be prepared in the context of the given object
            query.arguments_for(ast_node, arg_owner, parent_object: graphql_object)
          end
        end

        def delete_all_interpreter_context
          per_query_state = Fiber[:__graphql_runtime_info]
          if per_query_state
            per_query_state.delete(@query)
            if per_query_state.size == 0
              Fiber[:__graphql_runtime_info] = nil
            end
          end
          nil
        end

        def resolve_type(type, value)
          @current_trace.begin_resolve_type(type, value, context)
          resolved_type, resolved_value = @current_trace.resolve_type(query: query, type: type, object: value) do
            query.resolve_type(type, value)
          end
          @current_trace.end_resolve_type(type, value, context, resolved_type)

          if lazy?(resolved_type)
            GraphQL::Execution::Lazy.new do
              @current_trace.begin_resolve_type(type, value, context)
              @current_trace.resolve_type_lazy(query: query, type: type, object: value) do
                rt = schema.sync_lazy(resolved_type)
                @current_trace.end_resolve_type(type, value, context, rt)
                rt
              end
            end
          else
            [resolved_type, resolved_value]
          end
        end

        def lazy?(object)
          obj_class = object.class
          is_lazy = @lazy_cache[obj_class]
          if is_lazy.nil?
            is_lazy = @lazy_cache[obj_class] = @schema.lazy?(object)
          end
          is_lazy
        end
      end
    end
  end
end
