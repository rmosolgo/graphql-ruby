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
          def initialize(runtime:)
            @runtime = runtime
            @current_flush = []
            @dataloader = runtime.dataloader
            @lazies_at_depth = runtime.lazies_at_depth
            @running_eagerly = false
          end

          def append_step(step)
            @current_flush << step
          end

          def complete(eager: false)
            # p [self.class, __method__, eager, caller(1,1).first, @current_flush.size]
            prev_eagerly = @running_eagerly
            @running_eagerly = eager
            while (fl = @current_flush) && fl.any?
              @current_flush = []
              steps_to_rerun_after_lazy = []
              while fl.any?
                while (step = fl.shift)
                  step_finished = false
                  while !step_finished
                    # p [:run_step, step.inspect_step]
                    step_result = step.run_step
                    step_finished = step.step_finished?
                    if !step_finished && @runtime.lazy?(step_result)
                      # p [:lazy, step_result.class, step.depth]
                      @lazies_at_depth[step.depth] << step
                      steps_to_rerun_after_lazy << step
                      step_finished = true # we'll come back around to it
                    end
                  end

                  if @running_eagerly && @current_flush.any?
                    # This is for mutations. If a mutation parent field enqueues any child fields,
                    # we need to run those before running other mutation parent fields.
                    fl.unshift(*@current_flush)
                    @current_flush.clear
                  end
                end

                if @current_flush.any?
                  fl.concat(@current_flush)
                  @current_flush.clear
                else
                  fl.concat(steps_to_rerun_after_lazy)
                  steps_to_rerun_after_lazy.clear
                  @dataloader.run
                  Interpreter::Resolve.resolve_each_depth(@lazies_at_depth, @dataloader)
                end
              end
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

        attr_reader :dataloader, :current_trace, :lazies_at_depth

        attr_accessor :run_queue

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
          @run_queue = RunQueue.new(runtime: self)
        end

        def final_result
          # TODO can `graphql_result_data` be set to `nil` when `.wrap` fails?
          @response.respond_to?(:graphql_result_data) ? @response.graphql_result_data : @response
        end

        def inspect
          "#<#{self.class.name} response=#{@response.inspect}>"
        end

        class OperationDirectivesStep
          def initialize(runtime, object, method_to_call, directives, next_step)
            @runtime = runtime
            @object = object
            @method_to_call = method_to_call
            @directives = directives
            @next_step = next_step
          end

          def run_step
            @runtime.call_method_on_directives(@method_to_call, @object, @directives) do
              @runtime.run_queue.append_step(@next_step)
              @next_step
            end
          end

          def step_finished?
            true
          end

          def inspect_step
            "#{self.class.name.split("::").last}##{object_id}(#{@directives ? @directives.map(&:name).join(", ") : nil}) => #{@next_step.inspect_step}"
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
          when "OBJECT", "UNION", "INTERFACE"
            # TODO: use `nil` for top-level result when `.wrap` returns `nil`
            @response = GraphQLResultHash.new(self, nil, root_type, object, nil, false, selections, is_eager, ast_node, nil, nil)
            @response.base_path = base_path

            runtime_state.current_result = @response
            next_step = if !ast_node.directives.empty?
              OperationDirectivesStep.new(self, object, :resolve, ast_node.directives, @response)
            else
              @response
            end
            @run_queue.append_step(next_step)
          when "LIST"
            inner_type = root_type.unwrap
            case inner_type.kind.name
            when "SCALAR", "ENUM"
              result_name = ast_node.alias || ast_node.name
              field_defn = query.field_definition
              owner_type = field_defn.owner
              selection_result = GraphQLResultHash.new(self, nil, owner_type, nil, nil, false, EmptyObjects::EMPTY_ARRAY, false, ast_node, nil, nil)
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
              @run_queue.append_step(@response)
            end
          when "SCALAR", "ENUM"
            result_name = ast_node.alias || ast_node.name
            field_defn = query.field_definition
            owner_type = field_defn.owner
            selection_result = GraphQLResultHash.new(self, nil, owner_type, nil, nil, false, EmptyObjects::EMPTY_ARRAY, false, ast_node, nil, nil)
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

        class FieldResolveStep
          def initialize(runtime, field, ast_node, ast_nodes, result_name, selection_result)
            @runtime = runtime
            @field = field
            @object = selection_result.graphql_application_value
            if @field.dynamic_introspection
              @object = field.owner.wrap(@object, @runtime.context)
            end
            @ast_node = ast_node
            @ast_nodes = ast_nodes
            @result_name = result_name
            @selection_result = selection_result
            @next_selections = nil
            @step = :inspect_ast
          end

          attr_reader :selection_result

          def inspect_step
            "#{self.class.name.split("::").last}##{object_id}/#@step(#{@field.path} @ #{@selection_result.path.join(".")}.#{@result_name})"
          end

          def step_finished?
            @step == :finished
          end

          def depth
            @selection_result.depth + 1
          end

          attr_accessor :result

          def value # Lazy API
            @result = begin
              @runtime.schema.sync_lazy(@result)
            rescue GraphQL::ExecutionError => err
              err
            rescue StandardError => err
              begin
                @runtime.query.handle_or_reraise(err)
              rescue GraphQL::ExecutionError => ex_err
                ex_err
              end
            end
          end

          def run_step
            if @selection_result.graphql_dead
              @step = :finished
              return nil
            end
            case @step
            when :inspect_ast
              # Optimize for the case that field is selected only once
              if @ast_nodes.nil? || @ast_nodes.size == 1
                @next_selections = @ast_node.selections
                directives = @ast_node.directives
              else
                @next_selections = []
                directives = []
                @ast_nodes.each { |f|
                  @next_selections.concat(f.selections)
                  directives.concat(f.directives)
                }
              end

              if directives.any?
                @step = :finished # some way to detect whether the block below is called or not
                @runtime.call_method_on_directives(:resolve, @object, directives) do
                  @step = :load_arguments
                  self # TODO what kind of compatibility is possible here?
                end
              else
                # TODO some way to continue without this step
                @step = :load_arguments
              end
            when :load_arguments
              if !@field.any_arguments?
                @resolved_arguments = GraphQL::Execution::Interpreter::Arguments::EMPTY
                if @field.extras.size == 0
                  @kwarg_arguments = EmptyObjects::EMPTY_HASH
                  @step = :call_field_resolver # kwargs are already ready -- they're empty
                else
                  @step = :prepare_kwarg_arguments
                end
                nil
              else
                @step = :prepare_kwarg_arguments
                @runtime.query.arguments_cache.dataload_for(@ast_node, @field, @object) do |resolved_arguments|
                  @result = resolved_arguments
                end
                @result
              end
            when :prepare_kwarg_arguments
              if @resolved_arguments.nil? && @result.nil?
                @runtime.dataloader.run
              end
              @resolved_arguments ||= @result
              @result = nil
              if @resolved_arguments.is_a?(GraphQL::ExecutionError) || @resolved_arguments.is_a?(GraphQL::UnauthorizedError)
                return_type_non_null = @field.type.non_null?
                @runtime.continue_value(@resolved_arguments, @field, return_type_non_null, @ast_node, @result_name, @selection_result)
                @step = :finished
                return
              end

              @kwarg_arguments = if @field.extras.empty?
                if @resolved_arguments.empty?
                  # We can avoid allocating the `{ Symbol => Object }` hash in this case
                  EmptyObjects::EMPTY_HASH
                else
                  @resolved_arguments.keyword_arguments
                end
              else
                # Bundle up the extras, then make a new arguments instance
                # that includes the extras, too.
                extra_args = {}
                @field.extras.each do |extra|
                  case extra
                  when :ast_node
                    extra_args[:ast_node] = @ast_node
                  when :execution_errors
                    extra_args[:execution_errors] = ExecutionErrors.new(@runtime.context, @ast_node, @runtime.current_path)
                  when :path
                    extra_args[:path] = @runtime.current_path
                  when :lookahead
                    if !@field_ast_nodes
                      @field_ast_nodes = [@ast_node]
                    end

                    extra_args[:lookahead] = Execution::Lookahead.new(
                      query: @runtime.query,
                      ast_nodes: @field_ast_nodes,
                      field: @field,
                    )
                  when :argument_details
                    # Use this flag to tell Interpreter::Arguments to add itself
                    # to the keyword args hash _before_ freezing everything.
                    extra_args[:argument_details] = :__arguments_add_self
                  when :parent
                    parent_result = @selection_result.graphql_parent
                    if parent_result.is_a?(GraphQL::Execution::Interpreter::Runtime::GraphQLResultArray)
                      parent_result = parent_result.graphql_parent
                    end
                    parent_value = parent_result&.graphql_application_value&.object
                    extra_args[:parent] = parent_value
                  else
                    extra_args[extra] = @field.fetch_extra(extra, @runtime.context)
                  end
                end
                if !extra_args.empty?
                  @resolved_arguments = @resolved_arguments.merge_extras(extra_args)
                end
                @resolved_arguments.keyword_arguments
              end
              @step = :call_field_resolver
              nil
            when :call_field_resolver
              # if !directives.empty?
                # This might be executed in a different context; reset this info
              runtime_state = @runtime.get_current_runtime_state
              runtime_state.current_field = @field
              runtime_state.current_arguments = @resolved_arguments
              runtime_state.current_result_name = @result_name
              runtime_state.current_result = @selection_result
              # end

              # Actually call the field resolver and capture the result
              query = @runtime.query
              app_result = begin
                @runtime.current_trace.begin_execute_field(@field, @object, @kwarg_arguments, query)
                @runtime.current_trace.execute_field(field: @field, ast_node: @ast_node, query: query, object: @object, arguments: @kwarg_arguments) do
                  @field.resolve(@object, @kwarg_arguments, query.context)
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
              @runtime.current_trace.end_execute_field(@field, @object, @kwarg_arguments, query, app_result)
              @step = :handle_resolved_value
              @result = app_result
            when :handle_resolved_value
              runtime_state = @runtime.get_current_runtime_state
              runtime_state.current_field = @field
              runtime_state.current_arguments = @resolved_arguments
              runtime_state.current_result_name = @result_name
              runtime_state.current_result = @selection_result
              return_type = @field.type
              @result = @runtime.continue_value(@result, @field, return_type.non_null?, @ast_node, @result_name, @selection_result)

              if !HALT.equal?(@result)
                runtime_state = @runtime.get_current_runtime_state
                was_scoped = runtime_state.was_authorized_by_scope_items
                runtime_state.was_authorized_by_scope_items = nil
                @runtime.continue_field(@result, @field, return_type, @ast_node, @next_selections, false, @resolved_arguments, @result_name, @selection_result, was_scoped, runtime_state)
              else
                nil
              end
              @step = :finished
              nil
            else
              raise "Invariant: unexpected #{self.class} step: #{@step.inspect} (#{inspect_step})"
            end
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
          when "OBJECT", "UNION", "INTERFACE"
            response_hash = GraphQLResultHash.new(self, result_name, current_type, value, selection_result, is_non_null, next_selections, false, ast_node, arguments, field)
            response_hash.was_scoped = was_scoped
            @run_queue.append_step response_hash
          when "LIST"
            response_list = GraphQLResultArray.new(self, result_name, current_type, value, selection_result, is_non_null, next_selections, false, ast_node, arguments, field)
            set_result(selection_result, result_name, response_list, true, is_non_null)
            @run_queue.append_step(response_list)
            response_list # TODO smell this is used because its returned by `yield` inside a directive
          else
            raise "Invariant: Unhandled type kind #{current_type.kind} (#{current_type})"
          end
        end

        class ListItemStep
          def initialize(runtime, list_result, index, item_value)
            @runtime = runtime
            @list_result = list_result
            @index = index
            @item_value = item_value
            @step = :check_directives
          end

          def step_finished?
            @step == :finished
          end

          def inspect_step
            "#{self.class.name.split("::").last}##{object_id}@#{@index}"
          end

          def value # Lazy API
            @item_value = begin
              @runtime.schema.sync_lazy(@item_value)
            rescue GraphQL::ExecutionError => err
              err
            rescue StandardError => err
              begin
                @runtime.query.handle_or_reraise(err)
              rescue GraphQL::ExecutionError => ex_err
                ex_err
              end
            end
          end

          def depth
            @list_result.depth + 1
          end

          def run_step
            case @step
            when :check_directives
              if (dirs = @list_result.ast_node.directives).any?
                @step = :finished
              runtime_state = @runtime.get_current_runtime_state
              runtime_state.current_result_name = @index
              runtime_state.current_result = @list_result
                @runtime.call_method_on_directives(:resolve_each, @list_result.graphql_application_value, dirs) do
                  @step = :check_lazy_item
                end
              else
                @step = :check_lazy_item
              end
            when :check_lazy_item
              @step = :handle_item
              if @runtime.lazy?(@item_value)
                @item_value
              else
                nil
              end
            when :handle_item
              item_type = @list_result.graphql_result_type.of_type
              item_type_non_null = item_type.non_null?
              continue_value = @runtime.continue_value(@item_value, @list_result.graphql_field, item_type_non_null, @list_result.ast_node, @index, @list_result)
              if !HALT.equal?(continue_value)
                was_scoped = false # TODO!!
                @runtime.continue_field(continue_value, @list_result.graphql_field, item_type, @list_result.ast_node, @list_result.graphql_selections, false, @list_result.graphql_arguments, @index, @list_result, was_scoped, @runtime.get_current_runtime_state)
              end
              @step = :finished
            else
              raise "Invariant: unexpected step: #{inspect_step}"
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
