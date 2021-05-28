# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # I think it would be even better if we could somehow make
      # `continue_field` not recursive. "Trampolining" it somehow.
      #
      # @api private
      class Runtime

        module GraphQLResult
          # These methods are private concerns of GraphQL-Ruby,
          # they aren't guaranteed to continue working in the future.
          attr_accessor :graphql_dead, :graphql_parent, :graphql_result_name
          # Although these are used by only one of the Result classes,
          # it's handy to have the methods implemented on both (even though they just return `nil`)
          # because it makes it easy to check if anything is assigned.
          # @return [nil, Array<String>]
          attr_accessor :graphql_non_null_field_names
          # @return [nil, true]
          attr_accessor :graphql_non_null_list_items
        end

        class GraphQLResultHash < Hash
          include GraphQLResult
        end

        class GraphQLResultArray < Array
          include GraphQLResult
        end

        # @return [GraphQL::Query]
        attr_reader :query

        # @return [Class<GraphQL::Schema>]
        attr_reader :schema

        # @return [GraphQL::Query::Context]
        attr_reader :context

        # @return [Hash]
        attr_reader :response

        def initialize(query:)
          @query = query
          @dataloader = query.multiplex.dataloader
          @schema = query.schema
          @context = query.context
          @multiplex_context = query.multiplex.context
          @interpreter_context = @context.namespace(:interpreter)
          @response = GraphQLResultHash.new
          # A cache of { Class => { String => Schema::Field } }
          # Which assumes that MyObject.get_field("myField") will return the same field
          # during the lifetime of a query
          @fields_cache = Hash.new { |h, k| h[k] = {} }
          # { Class => Boolean }
          @lazy_cache = {}
        end

        def inspect
          "#<#{self.class.name} response=#{@response.inspect}>"
        end

        # This _begins_ the execution. Some deferred work
        # might be stored up in lazies.
        # @return [void]
        def run_eager
          root_operation = query.selected_operation
          root_op_type = root_operation.operation_type || "query"
          root_type = schema.root_type_for_operation(root_op_type)
          path = []
          set_all_interpreter_context(query.root_value, nil, nil, path)
          object_proxy = authorized_new(root_type, query.root_value, context)
          object_proxy = schema.sync_lazy(object_proxy)

          if object_proxy.nil?
            # Root .authorized? returned false.
            @response = nil
          else
            resolve_with_directives(object_proxy, root_operation) do # execute query level directives
              gathered_selections = gather_selections(object_proxy, root_type, root_operation.selections)
              # Make the first fiber which will begin execution
              @dataloader.append_job {
                evaluate_selections(
                  path,
                  context.scoped_context,
                  object_proxy,
                  root_type,
                  root_op_type == "mutation",
                  gathered_selections,
                  @response,
                )
              }
            end
          end
          delete_interpreter_context(:current_path)
          delete_interpreter_context(:current_field)
          delete_interpreter_context(:current_object)
          delete_interpreter_context(:current_arguments)
          nil
        end

        def gather_selections(owner_object, owner_type, selections, selections_by_name = {})
          selections.each do |node|
            # Skip gathering this if the directive says so
            if !directives_include?(node, owner_object, owner_type)
              next
            end

            case node
            when GraphQL::Language::Nodes::Field
              response_key = node.alias || node.name
              selections = selections_by_name[response_key]
              # if there was already a selection of this field,
              # use an array to hold all selections,
              # otherise, use the single node to represent the selection
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
            when GraphQL::Language::Nodes::InlineFragment
              if node.type
                type_defn = schema.get_type(node.type.name)
                # Faster than .map{}.include?()
                query.warden.possible_types(type_defn).each do |t|
                  if t == owner_type
                    gather_selections(owner_object, owner_type, node.selections, selections_by_name)
                    break
                  end
                end
              else
                # it's an untyped fragment, definitely continue
                gather_selections(owner_object, owner_type, node.selections, selections_by_name)
              end
            when GraphQL::Language::Nodes::FragmentSpread
              fragment_def = query.fragments[node.name]
              type_defn = schema.get_type(fragment_def.type.name)
              possible_types = query.warden.possible_types(type_defn)
              possible_types.each do |t|
                if t == owner_type
                  gather_selections(owner_object, owner_type, fragment_def.selections, selections_by_name)
                  break
                end
              end
            else
              raise "Invariant: unexpected selection class: #{node.class}"
            end
          end
          selections_by_name
        end

        NO_ARGS = {}.freeze

        # @return [void]
        def evaluate_selections(path, scoped_context, owner_object, owner_type, is_eager_selection, gathered_selections, selections_result)
          set_all_interpreter_context(owner_object, nil, nil, path)

          gathered_selections.each do |result_name, field_ast_nodes_or_ast_node|
            @dataloader.append_job {
              evaluate_selection(
                path, result_name, field_ast_nodes_or_ast_node, scoped_context, owner_object, owner_type, is_eager_selection, selections_result
              )
            }
          end

          nil
        end

        attr_reader :progress_path

        # @return [void]
        def evaluate_selection(path, result_name, field_ast_nodes_or_ast_node, scoped_context, owner_object, owner_type, is_eager_field, selections_result) # rubocop:disable Metrics/ParameterLists
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
          field_defn = @fields_cache[owner_type][field_name] ||= owner_type.get_field(field_name)
          is_introspection = false
          if field_defn.nil?
            field_defn = if owner_type == schema.query && (entry_point_field = schema.introspection_system.entry_point(name: field_name))
              is_introspection = true
              entry_point_field
            elsif (dynamic_field = schema.introspection_system.dynamic_field(name: field_name))
              is_introspection = true
              dynamic_field
            else
              raise "Invariant: no field for #{owner_type}.#{field_name}"
            end
          end
          return_type = field_defn.type

          next_path = path.dup
          next_path << result_name
          next_path.freeze

          # This seems janky, but we need to know
          # the field's return type at this path in order
          # to propagate `null`
          if return_type.non_null?
            (selections_result.graphql_non_null_field_names ||= []).push(result_name)
          end
          # Set this before calling `run_with_directives`, so that the directive can have the latest path
          set_all_interpreter_context(nil, field_defn, nil, next_path)

          context.scoped_context = scoped_context
          object = owner_object

          if is_introspection
            object = authorized_new(field_defn.owner, object, context)
          end

          total_args_count = field_defn.arguments.size
          if total_args_count == 0
            kwarg_arguments = GraphQL::Execution::Interpreter::Arguments::EMPTY
            evaluate_selection_with_args(kwarg_arguments, field_defn, next_path, ast_node, field_ast_nodes, scoped_context, owner_type, object, is_eager_field, result_name, selections_result)
          else
            # TODO remove all arguments(...) usages?
            @query.arguments_cache.dataload_for(ast_node, field_defn, object) do |resolved_arguments|
              evaluate_selection_with_args(resolved_arguments, field_defn, next_path, ast_node, field_ast_nodes, scoped_context, owner_type, object, is_eager_field, result_name, selections_result)
            end
          end
        end

        def evaluate_selection_with_args(kwarg_arguments, field_defn, next_path, ast_node, field_ast_nodes, scoped_context, owner_type, object, is_eager_field, result_name, selection_result)  # rubocop:disable Metrics/ParameterLists
          context.scoped_context = scoped_context
          return_type = field_defn.type
          after_lazy(kwarg_arguments, owner: owner_type, field: field_defn, path: next_path, ast_node: ast_node, scoped_context: context.scoped_context, owner_object: object, arguments: kwarg_arguments, result_name: result_name, result: selection_result) do |resolved_arguments|
            if resolved_arguments.is_a?(GraphQL::ExecutionError) || resolved_arguments.is_a?(GraphQL::UnauthorizedError)
              continue_value(next_path, resolved_arguments, owner_type, field_defn, return_type.non_null?, ast_node, result_name, selection_result)
              next
            end

            kwarg_arguments = if resolved_arguments.empty? && field_defn.extras.empty?
              # We can avoid allocating the `{ Symbol => Object }` hash in this case
              NO_ARGS
            else
              # Bundle up the extras, then make a new arguments instance
              # that includes the extras, too.
              extra_args = {}
              field_defn.extras.each do |extra|
                case extra
                when :ast_node
                  extra_args[:ast_node] = ast_node
                when :execution_errors
                  extra_args[:execution_errors] = ExecutionErrors.new(context, ast_node, next_path)
                when :path
                  extra_args[:path] = next_path
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
                when :irep_node
                  # This is used by `__typename` in order to support the legacy runtime,
                  # but it has no use here (and it's always `nil`).
                  # Stop adding it here to avoid the overhead of `.merge_extras` below.
                else
                  extra_args[extra] = field_defn.fetch_extra(extra, context)
                end
              end
              if extra_args.any?
                resolved_arguments = resolved_arguments.merge_extras(extra_args)
              end
              resolved_arguments.keyword_arguments
            end

            set_all_interpreter_context(nil, nil, kwarg_arguments, nil)

            # Optimize for the case that field is selected only once
            if field_ast_nodes.nil? || field_ast_nodes.size == 1
              next_selections = ast_node.selections
            else
              next_selections = []
              field_ast_nodes.each { |f| next_selections.concat(f.selections) }
            end

            field_result = resolve_with_directives(object, ast_node) do
              # Actually call the field resolver and capture the result
              app_result = begin
                query.with_error_handling do
                  query.trace("execute_field", {owner: owner_type, field: field_defn, path: next_path, ast_node: ast_node, query: query, object: object, arguments: kwarg_arguments}) do
                    field_defn.resolve(object, kwarg_arguments, context)
                  end
                end
              rescue GraphQL::ExecutionError => err
                err
              end
              after_lazy(app_result, owner: owner_type, field: field_defn, path: next_path, ast_node: ast_node, scoped_context: context.scoped_context, owner_object: object, arguments: kwarg_arguments, result_name: result_name, result: selection_result) do |inner_result|
                continue_value = continue_value(next_path, inner_result, owner_type, field_defn, return_type.non_null?, ast_node, result_name, selection_result)
                if HALT != continue_value
                  continue_field(next_path, continue_value, owner_type, field_defn, return_type, ast_node, next_selections, false, object, kwarg_arguments, result_name, selection_result)
                end
              end
            end

            # If this field is a root mutation field, immediately resolve
            # all of its child fields before moving on to the next root mutation field.
            # (Subselections of this mutation will still be resolved level-by-level.)
            if is_eager_field
              Interpreter::Resolve.resolve_all([field_result], @dataloader)
            else
              # Return this from `after_lazy` because it might be another lazy that needs to be resolved
              field_result
            end
          end
        end

        def dead_result?(selection_result)
          r = selection_result
          while r
            if r.graphql_dead
              return true
            else
              r = r.graphql_parent
            end
          end
          false
        end

        def set_result(selection_result, result_name, value)
          if !dead_result?(selection_result)
            if value.nil? &&
                ( # there are two conditions under which `nil` is not allowed in the response:
                  (selection_result.graphql_non_null_list_items) || # this value would be written into a list that doesn't allow nils
                  ((nn = selection_result.graphql_non_null_field_names) && nn.include?(result_name)) # this value would be written into a field that doesn't allow nils
                )
              # This is an invalid nil that should be propagated
              # One caller of this method passes a block,
              # namely when application code returns a `nil` to GraphQL and it doesn't belong there.
              # The other possibility for reaching here is when a field returns an ExecutionError, so we write
              # `nil` to the response, not knowing whether it's an invalid `nil` or not.
              # (And in that case, we don't have to call the schema's handler, since it's not a bug in the application.)
              # TODO the code is trying to tell me something.
              yield if block_given?
              parent = selection_result.graphql_parent
              name_in_parent = selection_result.graphql_result_name
              if parent.nil? # This is a top-level result hash
                @response = nil
              else
                set_result(parent, name_in_parent, nil)
                # This is odd, but it's how it used to work. Even if `parent` _would_ accept
                # a `nil`, it's marked dead. TODO: check the spec, is there a reason for this?
                parent.graphql_dead = true
              end
            else
              selection_result[result_name] = value
            end
          end
        end

        HALT = Object.new
        def continue_value(path, value, parent_type, field, is_non_null, ast_node, result_name, selection_result) # rubocop:disable Metrics/ParameterLists
          case value
          when nil
            if is_non_null
              set_result(selection_result, result_name, nil) do
                # This block is called if `result_name` is not dead. (Maybe a previous invalid nil caused it be marked dead.)
                err = parent_type::InvalidNullError.new(parent_type, field, value)
                schema.type_error(err, context)
              end
            else
              set_result(selection_result, result_name, nil)
            end
            HALT
          when GraphQL::Error
            # Handle these cases inside a single `when`
            # to avoid the overhead of checking three different classes
            # every time.
            if value.is_a?(GraphQL::ExecutionError)
              if !dead_result?(selection_result)
                value.path ||= path
                value.ast_node ||= ast_node
                context.errors << value
                set_result(selection_result, result_name, nil)
              end
              HALT
            elsif value.is_a?(GraphQL::UnauthorizedError)
              # this hook might raise & crash, or it might return
              # a replacement value
              next_value = begin
                schema.unauthorized_object(value)
              rescue GraphQL::ExecutionError => err
                err
              end
              continue_value(path, next_value, parent_type, field, is_non_null, ast_node, result_name, selection_result)
            elsif GraphQL::Execution::Execute::SKIP == value
              HALT
            else
              # What could this actually _be_? Anyhow,
              # preserve the default behavior of doing nothing with it.
              value
            end
          when Array
            # It's an array full of execution errors; add them all.
            if value.any? && value.all? { |v| v.is_a?(GraphQL::ExecutionError) }
              if !dead_result?(selection_result)
                value.each_with_index do |error, index|
                  error.ast_node ||= ast_node
                  error.path ||= path + (field.type.list? ? [index] : [])
                  context.errors << error
                end
                set_result(selection_result, result_name, nil)
              end
              HALT
            else
              value
            end
          when GraphQL::Execution::Interpreter::RawValue
            # Write raw value directly to the response without resolving nested objects
            set_result(selection_result, result_name, value.resolve)
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
        def continue_field(path, value, owner_type, field, current_type, ast_node, next_selections, is_non_null, owner_object, arguments, result_name, selection_result) # rubocop:disable Metrics/ParameterLists
          if current_type.non_null?
            current_type = current_type.of_type
            is_non_null = true
          end

          case current_type.kind.name
          when "SCALAR", "ENUM"
            r = current_type.coerce_result(value, context)
            set_result(selection_result, result_name, r)
            r
          when "UNION", "INTERFACE"
            resolved_type_or_lazy, resolved_value = resolve_type(current_type, value, path)
            resolved_value ||= value

            after_lazy(resolved_type_or_lazy, owner: current_type, path: path, ast_node: ast_node, scoped_context: context.scoped_context, field: field, owner_object: owner_object, arguments: arguments, trace: false, result_name: result_name, result: selection_result) do |resolved_type|
              possible_types = query.possible_types(current_type)

              if !possible_types.include?(resolved_type)
                parent_type = field.owner_type
                err_class = current_type::UnresolvedTypeError
                type_error = err_class.new(resolved_value, field, parent_type, resolved_type, possible_types)
                schema.type_error(type_error, context)
                set_result(selection_result, result_name, nil)
                nil
              else
                continue_field(path, resolved_value, owner_type, field, resolved_type, ast_node, next_selections, is_non_null, owner_object, arguments, result_name, selection_result)
              end
            end
          when "OBJECT"
            object_proxy = begin
              authorized_new(current_type, value, context)
            rescue GraphQL::ExecutionError => err
              err
            end
            after_lazy(object_proxy, owner: current_type, path: path, ast_node: ast_node, scoped_context: context.scoped_context, field: field, owner_object: owner_object, arguments: arguments, trace: false, result_name: result_name, result: selection_result) do |inner_object|
              continue_value = continue_value(path, inner_object, owner_type, field, is_non_null, ast_node, result_name, selection_result)
              if HALT != continue_value
                response_hash = GraphQLResultHash.new
                response_hash.graphql_parent = selection_result
                response_hash.graphql_result_name = result_name
                set_result(selection_result, result_name, response_hash)
                gathered_selections = gather_selections(continue_value, current_type, next_selections)
                evaluate_selections(path, context.scoped_context, continue_value, current_type, false, gathered_selections, response_hash)
                response_hash
              end
            end
          when "LIST"
            inner_type = current_type.of_type
            response_list = GraphQLResultArray.new
            response_list.graphql_non_null_list_items = inner_type.non_null?
            response_list.graphql_parent = selection_result
            response_list.graphql_result_name = result_name
            set_result(selection_result, result_name, response_list)

            idx = 0
            scoped_context = context.scoped_context
            begin
              value.each do |inner_value|
                next_path = path.dup
                next_path << idx
                this_idx = idx
                next_path.freeze
                idx += 1
                # This will update `response_list` with the lazy
                after_lazy(inner_value, owner: inner_type, path: next_path, ast_node: ast_node, scoped_context: scoped_context, field: field, owner_object: owner_object, arguments: arguments, result_name: this_idx, result: response_list) do |inner_inner_value|
                  continue_value = continue_value(next_path, inner_inner_value, owner_type, field, inner_type.non_null?, ast_node, this_idx, response_list)
                  if HALT != continue_value
                    continue_field(next_path, continue_value, owner_type, field, inner_type, ast_node, next_selections, false, owner_object, arguments, this_idx, response_list)
                  end
                end
              end
            rescue NoMethodError => err
              # Ruby 2.2 doesn't have NoMethodError#receiver, can't check that one in this case. (It's been EOL since 2017.)
              if err.name == :each && (err.respond_to?(:receiver) ? err.receiver == value : true)
                # This happens when the GraphQL schema doesn't match the implementation. Help the dev debug.
                raise ListResultFailedError.new(value: value, field: field, path: path)
              else
                # This was some other NoMethodError -- let it bubble to reveal the real error.
                raise
              end
            end

            response_list
          else
            raise "Invariant: Unhandled type kind #{current_type.kind} (#{current_type})"
          end
        end

        def resolve_with_directives(object, ast_node, &block)
          return yield if ast_node.directives.empty?
          run_directive(object, ast_node, 0, &block)
        end

        def run_directive(object, ast_node, idx, &block)
          dir_node = ast_node.directives[idx]
          if !dir_node
            yield
          else
            dir_defn = schema.directives.fetch(dir_node.name)
            if !dir_defn.is_a?(Class)
              dir_defn = dir_defn.type_class || raise("Only class-based directives are supported (not `@#{dir_node.name}`)")
            end
            dir_args = arguments(nil, dir_defn, dir_node).keyword_arguments
            dir_defn.resolve(object, dir_args, context) do
              run_directive(object, ast_node, idx + 1, &block)
            end
          end
        end

        # Check {Schema::Directive.include?} for each directive that's present
        def directives_include?(node, graphql_object, parent_type)
          node.directives.each do |dir_node|
            dir_defn = schema.directives.fetch(dir_node.name).type_class || raise("Only class-based directives are supported (not #{dir_node.name.inspect})")
            args = arguments(graphql_object, dir_defn, dir_node).keyword_arguments
            if !dir_defn.include?(graphql_object, args, context)
              return false
            end
          end
          true
        end

        def set_all_interpreter_context(object, field, arguments, path)
          if object
            @context[:current_object] = @interpreter_context[:current_object] = object
          end
          if field
            @context[:current_field] = @interpreter_context[:current_field] = field
          end
          if arguments
            @context[:current_arguments] = @interpreter_context[:current_arguments] = arguments
          end
          if path
            @context[:current_path] = @interpreter_context[:current_path] = path
          end
        end

        # @param obj [Object] Some user-returned value that may want to be batched
        # @param path [Array<String>]
        # @param field [GraphQL::Schema::Field]
        # @param eager [Boolean] Set to `true` for mutation root fields only
        # @param trace [Boolean] If `false`, don't wrap this with field tracing
        # @return [GraphQL::Execution::Lazy, Object] If loading `object` will be deferred, it's a wrapper over it.
        def after_lazy(lazy_obj, owner:, field:, path:, scoped_context:, owner_object:, arguments:, ast_node:, result:, result_name:, eager: false, trace: true, &block)
          if lazy?(lazy_obj)
            lazy = GraphQL::Execution::Lazy.new(path: path, field: field) do
              set_all_interpreter_context(owner_object, field, arguments, path)
              context.scoped_context = scoped_context
              # Wrap the execution of _this_ method with tracing,
              # but don't wrap the continuation below
              inner_obj = begin
                query.with_error_handling do
                  if trace
                    query.trace("execute_field_lazy", {owner: owner, field: field, path: path, query: query, object: owner_object, arguments: arguments, ast_node: ast_node}) do
                      schema.sync_lazy(lazy_obj)
                    end
                  else
                    schema.sync_lazy(lazy_obj)
                  end
                end
                rescue GraphQL::ExecutionError, GraphQL::UnauthorizedError => err
                  err
              end
              yield(inner_obj)
            end

            if eager
              lazy.value
            else
              set_result(result, result_name, lazy)
              lazy
            end
          else
            set_all_interpreter_context(owner_object, field, arguments, path)
            yield(lazy_obj)
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

        # Set this pair in the Query context, but also in the interpeter namespace,
        # for compatibility.
        def set_interpreter_context(key, value)
          @interpreter_context[key] = value
          @context[key] = value
        end

        def delete_interpreter_context(key)
          @interpreter_context.delete(key)
          @context.delete(key)
        end

        def resolve_type(type, value, path)
          trace_payload = { context: context, type: type, object: value, path: path }
          resolved_type, resolved_value = query.trace("resolve_type", trace_payload) do
            query.resolve_type(type, value)
          end

          if lazy?(resolved_type)
            GraphQL::Execution::Lazy.new do
              query.trace("resolve_type_lazy", trace_payload) do
                schema.sync_lazy(resolved_type)
              end
            end
          else
            [resolved_type, resolved_value]
          end
        end

        def authorized_new(type, value, context)
          type.authorized_new(value, context)
        end

        def lazy?(object)
          @lazy_cache.fetch(object.class) {
            @lazy_cache[object.class] = @schema.lazy?(object)
          }
        end
      end
    end
  end
end
