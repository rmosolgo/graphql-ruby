# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # I think it would be even better if we could somehow make
      # `continue_field` not recursive. "Trampolining" it somehow.
      #
      # @api private
      class Runtime
        # @return [GraphQL::Query]
        attr_reader :query

        # @return [Class<GraphQL::Schema>]
        attr_reader :schema

        # @return [GraphQL::Query::Context]
        attr_reader :context

        def initialize(query:, response:)
          @query = query
          @schema = query.schema
          @context = query.context
          @interpreter_context = @context.namespace(:interpreter)
          @response = response
          @dead_paths = {}
          @types_at_paths = {}
          # A cache of { Class => { String => Schema::Field } }
          # Which assumes that MyObject.get_field("myField") will return the same field
          # during the lifetime of a query
          @fields_cache = Hash.new { |h, k| h[k] = {} }
        end

        def final_value
          @response.final_value
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
          @interpreter_context[:current_object] = query.root_value
          @interpreter_context[:current_path] = path
          object_proxy = authorized_new(root_type, query.root_value, context, path)
          object_proxy = schema.sync_lazy(object_proxy)
          if object_proxy.nil?
            # Root .authorized? returned false.
            write_in_response(path, nil)
            nil
          else
            evaluate_selections(path, context.scoped_context, object_proxy, root_type, root_operation.selections, root_operation_type: root_op_type)
            nil
          end
        end

        def gather_selections(owner_object, owner_type, selections, selections_by_name)
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
        end

        def evaluate_selections(path, scoped_context, owner_object, owner_type, selections, root_operation_type: nil)
          @interpreter_context[:current_object] = owner_object
          @interpreter_context[:current_path] = path
          selections_by_name = {}
          gather_selections(owner_object, owner_type, selections, selections_by_name)
          selections_by_name.each do |result_name, field_ast_nodes_or_ast_node|
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
            set_type_at_path(next_path, return_type)
            # Set this before calling `run_with_directives`, so that the directive can have the latest path
            @interpreter_context[:current_path] = next_path
            @interpreter_context[:current_field] = field_defn

            context.scoped_context = scoped_context
            object = owner_object

            if is_introspection
              object = authorized_new(field_defn.owner, object, context, next_path)
            end

            begin
              kwarg_arguments = arguments(object, field_defn, ast_node)
            rescue GraphQL::ExecutionError => e
              continue_value(next_path, e, field_defn, return_type.non_null?, ast_node)
              next
            end

            # It might turn out that making arguments for every field is slow.
            # If we have to cache them, we'll need a more subtle approach here.
            field_defn.extras.each do |extra|
              case extra
              when :ast_node
                kwarg_arguments[:ast_node] = ast_node
              when :execution_errors
                kwarg_arguments[:execution_errors] = ExecutionErrors.new(context, ast_node, next_path)
              when :path
                kwarg_arguments[:path] = next_path
              when :lookahead
                if !field_ast_nodes
                  field_ast_nodes = [ast_node]
                end
                kwarg_arguments[:lookahead] = Execution::Lookahead.new(
                  query: query,
                  ast_nodes: field_ast_nodes,
                  field: field_defn,
                )
              else
                kwarg_arguments[extra] = field_defn.fetch_extra(extra, context)
              end
            end

            @interpreter_context[:current_arguments] = kwarg_arguments

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
                  query.trace("execute_field", {owner: owner_type, field: field_defn, path: next_path, query: query, object: object, arguments: kwarg_arguments}) do
                    field_defn.resolve(object, kwarg_arguments, context)
                  end
                end
              rescue GraphQL::ExecutionError => err
                err
              end
              after_lazy(app_result, owner: owner_type, field: field_defn, path: next_path, scoped_context: context.scoped_context, owner_object: object, arguments: kwarg_arguments) do |inner_result|
                continue_value = continue_value(next_path, inner_result, field_defn, return_type.non_null?, ast_node)
                if RawValue === continue_value
                  # Write raw value directly to the response without resolving nested objects
                  write_in_response(next_path, continue_value.resolve)
                elsif HALT != continue_value
                  continue_field(next_path, continue_value, field_defn, return_type, ast_node, next_selections, false, object, kwarg_arguments)
                end
              end
            end

            # If this field is a root mutation field, immediately resolve
            # all of its child fields before moving on to the next root mutation field.
            # (Subselections of this mutation will still be resolved level-by-level.)
            if root_operation_type == "mutation"
              Interpreter::Resolve.resolve_all([field_result])
            else
              field_result
            end
          end
        end

        HALT = Object.new
        def continue_value(path, value, field, is_non_null, ast_node)
          if value.nil?
            if is_non_null
              err = GraphQL::InvalidNullError.new(field.owner, field, value)
              write_invalid_null_in_response(path, err)
            else
              write_in_response(path, nil)
            end
            HALT
          elsif value.is_a?(GraphQL::ExecutionError)
            value.path ||= path
            value.ast_node ||= ast_node
            write_execution_errors_in_response(path, [value])
            HALT
          elsif value.is_a?(Array) && value.any? && value.all? { |v| v.is_a?(GraphQL::ExecutionError) }
            value.each_with_index do |error, index|
              error.ast_node ||= ast_node
              error.path ||= path + (field.type.list? ? [index] : [])
            end
            write_execution_errors_in_response(path, value)
            HALT
          elsif value.is_a?(GraphQL::UnauthorizedError)
            # this hook might raise & crash, or it might return
            # a replacement value
            next_value = begin
              schema.unauthorized_object(value)
            rescue GraphQL::ExecutionError => err
              err
            end

            continue_value(path, next_value, field, is_non_null, ast_node)
          elsif GraphQL::Execution::Execute::SKIP == value
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
        def continue_field(path, value, field, type, ast_node, next_selections, is_non_null, owner_object, arguments) # rubocop:disable Metrics/ParameterLists
          case type.kind.name
          when "SCALAR", "ENUM"
            r = type.coerce_result(value, context)
            write_in_response(path, r)
            r
          when "UNION", "INTERFACE"
            resolved_type_or_lazy = resolve_type(type, value, path)
            after_lazy(resolved_type_or_lazy, owner: type, path: path, scoped_context: context.scoped_context, field: field, owner_object: owner_object, arguments: arguments, trace: false) do |resolved_type|
              possible_types = query.possible_types(type)

              if !possible_types.include?(resolved_type)
                parent_type = field.owner
                type_error = GraphQL::UnresolvedTypeError.new(value, field, parent_type, resolved_type, possible_types)
                schema.type_error(type_error, context)
                write_in_response(path, nil)
                nil
              else
                continue_field(path, value, field, resolved_type, ast_node, next_selections, is_non_null, owner_object, arguments)
              end
            end
          when "OBJECT"
            object_proxy = begin
              authorized_new(type, value, context, path)
            rescue GraphQL::ExecutionError => err
              err
            end
            after_lazy(object_proxy, owner: type, path: path, scoped_context: context.scoped_context, field: field, owner_object: owner_object, arguments: arguments, trace: false) do |inner_object|
              continue_value = continue_value(path, inner_object, field, is_non_null, ast_node)
              if HALT != continue_value
                response_hash = {}
                write_in_response(path, response_hash)
                evaluate_selections(path, context.scoped_context, continue_value, type, next_selections)
                response_hash
              end
            end
          when "LIST"
            response_list = []
            write_in_response(path, response_list)
            inner_type = type.of_type
            idx = 0
            scoped_context = context.scoped_context
            value.each do |inner_value|
              next_path = path.dup
              next_path << idx
              next_path.freeze
              idx += 1
              set_type_at_path(next_path, inner_type)
              # This will update `response_list` with the lazy
              after_lazy(inner_value, owner: inner_type, path: next_path, scoped_context: scoped_context, field: field, owner_object: owner_object, arguments: arguments) do |inner_inner_value|
                continue_value = continue_value(next_path, inner_inner_value, field, inner_type.non_null?, ast_node)
                if HALT != continue_value
                  continue_field(next_path, continue_value, field, inner_type, ast_node, next_selections, false, owner_object, arguments)
                end
              end
            end
            response_list
          when "NON_NULL"
            inner_type = type.of_type
            # Don't `set_type_at_path` because we want the static type,
            # we're going to use that to determine whether a `nil` should be propagated or not.
            continue_field(path, value, field, inner_type, ast_node, next_selections, true, owner_object, arguments)
          else
            raise "Invariant: Unhandled type kind #{type.kind} (#{type})"
          end
        end

        def resolve_with_directives(object, ast_node)
          run_directive(object, ast_node, 0) { yield }
        end

        def run_directive(object, ast_node, idx)
          dir_node = ast_node.directives[idx]
          if !dir_node
            yield
          else
            dir_defn = schema.directives.fetch(dir_node.name)
            if !dir_defn.is_a?(Class)
              dir_defn = dir_defn.type_class || raise("Only class-based directives are supported (not `@#{dir_node.name}`)")
            end
            dir_args = arguments(nil, dir_defn, dir_node)
            dir_defn.resolve(object, dir_args, context) do
              run_directive(object, ast_node, idx + 1) { yield }
            end
          end
        end

        # Check {Schema::Directive.include?} for each directive that's present
        def directives_include?(node, graphql_object, parent_type)
          node.directives.each do |dir_node|
            dir_defn = schema.directives.fetch(dir_node.name).type_class || raise("Only class-based directives are supported (not #{dir_node.name.inspect})")
            args = arguments(graphql_object, dir_defn, dir_node)
            if !dir_defn.include?(graphql_object, args, context)
              return false
            end
          end
          true
        end

        # @param obj [Object] Some user-returned value that may want to be batched
        # @param path [Array<String>]
        # @param field [GraphQL::Schema::Field]
        # @param eager [Boolean] Set to `true` for mutation root fields only
        # @param trace [Boolean] If `false`, don't wrap this with field tracing
        # @return [GraphQL::Execution::Lazy, Object] If loading `object` will be deferred, it's a wrapper over it.
        def after_lazy(lazy_obj, owner:, field:, path:, scoped_context:, owner_object:, arguments:, eager: false, trace: true)
          @interpreter_context[:current_object] = owner_object
          @interpreter_context[:current_arguments] = arguments
          @interpreter_context[:current_path] = path
          @interpreter_context[:current_field] = field
          if schema.lazy?(lazy_obj)
            lazy = GraphQL::Execution::Lazy.new(path: path, field: field) do
              @interpreter_context[:current_path] = path
              @interpreter_context[:current_field] = field
              @interpreter_context[:current_object] = owner_object
              @interpreter_context[:current_arguments] = arguments
              context.scoped_context = scoped_context
              # Wrap the execution of _this_ method with tracing,
              # but don't wrap the continuation below
              inner_obj = begin
                query.with_error_handling do
                  if trace
                    query.trace("execute_field_lazy", {owner: owner, field: field, path: path, query: query, object: owner_object, arguments: arguments}) do
                      schema.sync_lazy(lazy_obj)
                    end
                  else
                    schema.sync_lazy(lazy_obj)
                  end
                end
                rescue GraphQL::ExecutionError, GraphQL::UnauthorizedError => err
                  yield(err)
              end
              after_lazy(inner_obj, owner: owner, field: field, path: path, scoped_context: context.scoped_context, owner_object: owner_object, arguments: arguments, eager: eager) do |really_inner_obj|
                yield(really_inner_obj)
              end
            end

            if eager
              lazy.value
            else
              write_in_response(path, lazy)
              lazy
            end
          else
            yield(lazy_obj)
          end
        end

        NO_VALUE_GIVEN = Object.new

        def prepare_args_hash(ast_arg_or_hash_or_value)
          case ast_arg_or_hash_or_value
          when Hash
            args_hash = {}
            ast_arg_or_hash_or_value.each do |k, v|
              args_hash[k] = prepare_args_hash(v)
            end
            args_hash
          when Array
            ast_arg_or_hash_or_value.map { |v| prepare_args_hash(v) }
          when GraphQL::Language::Nodes::Field, GraphQL::Language::Nodes::InputObject, GraphQL::Language::Nodes::Directive
            args_hash = {}
            ast_arg_or_hash_or_value.arguments.each do |arg|
              v = prepare_args_hash(arg.value)
              if v != NO_VALUE_GIVEN
                args_hash[arg.name] = v
              end
            end
            args_hash
          when GraphQL::Language::Nodes::VariableIdentifier
            if query.variables.key?(ast_arg_or_hash_or_value.name)
              variable_value = query.variables[ast_arg_or_hash_or_value.name]
              prepare_args_hash(variable_value)
            else
              NO_VALUE_GIVEN
            end
          when GraphQL::Language::Nodes::Enum
            ast_arg_or_hash_or_value.name
          when GraphQL::Language::Nodes::NullValue
            nil
          else
            ast_arg_or_hash_or_value
          end
        end

        def arguments(graphql_object, arg_owner, ast_node_or_hash)
          # First, normalize all AST or Ruby values to a plain Ruby hash
          args_hash = prepare_args_hash(ast_node_or_hash)
          # Then call into the schema to coerce those incoming values
          arg_owner.coerce_arguments(graphql_object, args_hash, context)
        end

        def write_invalid_null_in_response(path, invalid_null_error)
          if !dead_path?(path)
            schema.type_error(invalid_null_error, context)
            write_in_response(path, nil)
            add_dead_path(path)
          end
        end

        def write_execution_errors_in_response(path, errors)
          if !dead_path?(path)
            errors.each do |v|
              context.errors << v
            end
            write_in_response(path, nil)
            add_dead_path(path)
          end
        end

        def write_in_response(path, value)
          if dead_path?(path)
            return
          else
            if value.nil? && path.any? && type_at(path).non_null?
              # This nil is invalid, try writing it at the previous spot
              propagate_path = path[0..-2]
              write_in_response(propagate_path, value)
              add_dead_path(propagate_path)
            else
              @response.write(path, value)
            end
          end
        end

        # To propagate nulls, we have to know what the field type was
        # at previous parts of the response.
        # This hash matches the response
        def type_at(path)
          t = @types_at_paths
          path.each do |part|
            t = t[part] || (raise("Invariant: #{part.inspect} not found in #{t}"))
          end
          t = t[:__type]
          t
        end

        def set_type_at_path(path, type)
          types = @types_at_paths
          path.each do |part|
            types = types[part] ||= {}
          end
          # Use this magic key so that the hash contains:
          # - string keys for nested fields
          # - :__type for the object type of a selection
          types[:__type] ||= type
          nil
        end

        # Mark `path` as having been permanently nulled out.
        # No values will be added beyond that path.
        def add_dead_path(path)
          dead = @dead_paths
          path.each do |part|
            dead = dead[part] ||= {}
          end
          dead[:__dead] = true
        end

        def dead_path?(path)
          res = @dead_paths
          path.each do |part|
            if res
              if res[:__dead]
                break
              else
                res = res[part]
              end
            end
          end
          res && res[:__dead]
        end

        def resolve_type(type, value, path)
          trace_payload = { context: context, type: type, object: value, path: path }
          resolved_type = query.trace("resolve_type", trace_payload) do
            query.resolve_type(type, value)
          end

          if schema.lazy?(resolved_type)
            GraphQL::Execution::Lazy.new do
              query.trace("resolve_type_lazy", trace_payload) do
                schema.sync_lazy(resolved_type)
              end
            end
          else
            resolved_type
          end
        end

        def authorized_new(type, value, context, path)
          trace_payload = { context: context, type: type, object: value, path: path }

          auth_val = context.query.trace("authorized", trace_payload) do
            type.authorized_new(value, context)
          end

          if context.schema.lazy?(auth_val)
            GraphQL::Execution::Lazy.new do
              context.query.trace("authorized_lazy", trace_payload) do
                context.schema.sync_lazy(auth_val)
              end
            end
          else
            auth_val
          end
        end
      end
    end
  end
end
