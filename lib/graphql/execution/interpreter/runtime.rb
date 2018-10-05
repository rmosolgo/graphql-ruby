# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # I think it would be even better if we could somehow make
      # `continue_field` not recursive. "Trampolining" it somehow.
      class Runtime
        # @return [GraphQL::Query]
        attr_reader :query

        # @return [Class]
        attr_reader :schema

        # @return [GraphQL::Query::Context]
        attr_reader :context

        def initialize(query:, lazies:, response:)
          @query = query
          @schema = query.schema
          @context = query.context
          @lazies = lazies
          @response = response
          @dead_paths = {}
          @types_at_paths = {}
        end

        def final_value
          @response.final_value
        end

        def inspect
          "#<#{self.class.name} response=#{@response.inspect}>"
        end

        # This _begins_ the execution. Some deferred work
        # might be stored up in {@lazies}.
        # @return [void]
        def run_eager
          root_operation = query.selected_operation
          root_op_type = root_operation.operation_type || "query"
          legacy_root_type = schema.root_type_for_operation(root_op_type)
          root_type = legacy_root_type.metadata[:type_class] || raise("Invariant: type must be class-based: #{legacy_root_type}")
          object_proxy = root_type.authorized_new(query.root_value, context)

          path = []
          evaluate_selections(path, object_proxy, root_type, root_operation.selections, root_operation_type: root_op_type)
        end

        private

        def gather_selections(owner_type, selections, selections_by_name)
          selections.each do |node|
            case node
            when GraphQL::Language::Nodes::Field
              if passes_skip_and_include?(node)
                response_key = node.alias || node.name
                s = selections_by_name[response_key] ||= []
                s << node
              end
            when GraphQL::Language::Nodes::InlineFragment
              if passes_skip_and_include?(node)
                include_fragmment = if node.type
                  type_defn = schema.types[node.type.name]
                  type_defn = type_defn.metadata[:type_class]
                  possible_types = query.warden.possible_types(type_defn).map { |t| t.metadata[:type_class] }
                  possible_types.include?(owner_type)
                else
                  true
                end
                if include_fragmment
                  gather_selections(owner_type, node.selections, selections_by_name)
                end
              end
            when GraphQL::Language::Nodes::FragmentSpread
              if passes_skip_and_include?(node)
                fragment_def = query.fragments[node.name]
                type_defn = schema.types[fragment_def.type.name]
                type_defn = type_defn.metadata[:type_class]
                possible_types = schema.possible_types(type_defn).map { |t| t.metadata[:type_class] }
                if possible_types.include?(owner_type)
                  gather_selections(owner_type, fragment_def.selections, selections_by_name)
                end
              end
            else
              raise "Invariant: unexpected selection class: #{node.class}"
            end
          end
        end

        def evaluate_selections(path, owner_object, owner_type, selections, root_operation_type: nil)
          selections_by_name = {}
          owner_type = resolve_if_late_bound_type(owner_type)
          gather_selections(owner_type, selections, selections_by_name)
          selections_by_name.each do |result_name, fields|
            ast_node = fields.first
            field_name = ast_node.name
            field_defn = owner_type.fields[field_name]
            is_introspection = false
            if field_defn.nil?
              field_defn = if owner_type == schema.query.metadata[:type_class] && (entry_point_field = schema.introspection_system.entry_point(name: field_name))
                is_introspection = true
                entry_point_field.metadata[:type_class]
              elsif (dynamic_field = schema.introspection_system.dynamic_field(name: field_name))
                is_introspection = true
                dynamic_field.metadata[:type_class]
              else
                raise "Invariant: no field for #{owner_type}.#{field_name}"
              end
            end

            return_type = resolve_if_late_bound_type(field_defn.type)

            next_path = [*path, result_name].freeze
            # This seems janky, but we need to know
            # the field's return type at this path in order
            # to propagate `null`
            set_type_at_path(next_path, return_type)

            object = owner_object

            if is_introspection
              object = field_defn.owner.authorized_new(object, context)
            end

            kwarg_arguments = arguments(object, field_defn, ast_node)
            # It might turn out that making arguments for every field is slow.
            # If we have to cache them, we'll need a more subtle approach here.
            if field_defn.extras.include?(:ast_node)
              kwarg_arguments[:ast_node] = ast_node
            end
            if field_defn.extras.include?(:execution_errors)
              kwarg_arguments[:execution_errors] = ExecutionErrors.new(context, ast_node, next_path)
            end

            next_selections = fields.inject([]) { |memo, f| memo.concat(f.selections) }

            app_result = query.trace("execute_field", {field: field_defn, path: next_path}) do
              field_defn.resolve_field_2(object, kwarg_arguments, context)
            end

            after_lazy(app_result, field: field_defn, path: next_path, eager: root_operation_type == "mutation") do |inner_result|
              should_continue, continue_value = continue_value(next_path, inner_result, field_defn, return_type, ast_node)
              if should_continue
                continue_field(next_path, continue_value, field_defn, return_type, ast_node, next_selections)
              end
            end
          end
        end

        def continue_value(path, value, field, as_type, ast_node)
          if value.nil? || value.is_a?(GraphQL::ExecutionError)
            if value.nil?
              if as_type.non_null?
                err = GraphQL::InvalidNullError.new(field.owner, field, value)
                write_in_response(path, err, propagating_nil: true)
              else
                write_in_response(path, nil)
              end
            else
              value.path ||= path
              value.ast_node ||= ast_node
              write_in_response(path, value, propagating_nil: as_type.non_null?)
            end
            false
          elsif value.is_a?(Array) && value.all? { |v| v.is_a?(GraphQL::ExecutionError) }
            value.each do |v|
              v.path ||= path
              v.ast_node ||= ast_node
            end
            write_in_response(path, value, propagating_nil: as_type.non_null?)
            false
          elsif value.is_a?(GraphQL::UnauthorizedError)
            # this hook might raise & crash, or it might return
            # a replacement value
            next_value = begin
              schema.unauthorized_object(value)
            rescue GraphQL::ExecutionError => err
              err
            end

            continue_value(path, next_value, field, as_type, ast_node)
          elsif GraphQL::Execution::Execute::SKIP == value
            false
          else
            return true, value
          end
        end

        def continue_field(path, value, field, type, ast_node, next_selections)
          type = resolve_if_late_bound_type(type)

          case type.kind
          when TypeKinds::SCALAR, TypeKinds::ENUM
            r = type.coerce_result(value, context)
            write_in_response(path, r)
          when TypeKinds::UNION, TypeKinds::INTERFACE
            resolved_type = query.resolve_type(type, value)
            possible_types = query.possible_types(type)

            if !possible_types.include?(resolved_type)
              parent_type = field.owner
              type_error = GraphQL::UnresolvedTypeError.new(value, field, parent_type, resolved_type, possible_types)
              schema.type_error(type_error, context)
              write_in_response(path, nil, propagating_nil: field.type.non_null?)
            else
              resolved_type = resolved_type.metadata[:type_class]
              continue_field(path, value, field, resolved_type, ast_node, next_selections)
            end
          when TypeKinds::OBJECT
            object_proxy = begin
              type.authorized_new(value, context)
            rescue GraphQL::ExecutionError => err
              err
            end
            after_lazy(object_proxy, path: path, field: field) do |inner_object|
              should_continue, continue_value = continue_value(path, inner_object, field, type, ast_node)
              if should_continue
                write_in_response(path, {})
                evaluate_selections(path, continue_value, type, next_selections)
              end
            end
          when TypeKinds::LIST
            write_in_response(path, [])
            inner_type = type.of_type
            value.each_with_index.each do |inner_value, idx|
              next_path = [*path, idx].freeze
              set_type_at_path(next_path, inner_type)
              after_lazy(inner_value, path: next_path, field: field) do |inner_inner_value|
                should_continue, continue_value = continue_value(next_path, inner_inner_value, field, inner_type, ast_node)
                if should_continue
                  continue_field(next_path, continue_value, field, inner_type, ast_node, next_selections)
                end
              end
            end
          when TypeKinds::NON_NULL
            inner_type = type.of_type
            # Don't `set_type_at_path` because we want the static type,
            # we're going to use that to determine whether a `nil` should be propagated or not.
            continue_field(path, value, field, inner_type, ast_node, next_selections)
          else
            raise "Invariant: Unhandled type kind #{type.kind} (#{type})"
          end
        end

        def passes_skip_and_include?(node)
          # Eventually this should actually call out to the directives
          # instead of having magical hard-coded behavior.
          node.directives.each do |dir|
            dir_defn = schema.directives.fetch(dir.name)
            if dir.name == "skip" && arguments(nil, dir_defn, dir)[:if] == true
              return false
            elsif dir.name == "include" && arguments(nil, dir_defn, dir)[:if] == false
              return false
            end
          end
          true
        end

        def resolve_if_late_bound_type(type)
          if type.is_a?(GraphQL::Schema::LateBoundType)
            query.warden.get_type(type.name).metadata[:type_class]
          else
            type
          end
        end

        # @param obj [Object] Some user-returned value that may want to be batched
        # @param path [Array<String>]
        # @param field [GraphQL::Schema::Field]
        # @param eager [Boolean] Set to `true` for mutation root fields only
        # @return [GraphQL::Execution::Lazy, Object] If loading `object` will be deferred, it's a wrapper over it.
        def after_lazy(obj, field:, path:, eager: false)
          if schema.lazy?(obj)
            lazy = GraphQL::Execution::Lazy.new do
              # Wrap the execution of _this_ method with tracing,
              # but don't wrap the continuation below
              inner_obj = query.trace("execute_field_lazy", {field: field, path: path}) do
                method_name = schema.lazy_method_name(obj)
                begin
                  obj.public_send(method_name)
                rescue GraphQL::ExecutionError, GraphQL::UnauthorizedError => err
                  yield(err)
                end
              end
              after_lazy(inner_obj, field: field, path: path, eager: eager) do |really_inner_obj|
                yield(really_inner_obj)
              end
            end

            if eager
              lazy.value
            else
              @lazies << lazy
            end
          else
            yield(obj)
          end
        end
        def arguments(graphql_object, arg_owner, ast_node)
          kwarg_arguments = {}
          ast_node.arguments.each do |arg|
            arg_defn = arg_owner.arguments[arg.name]
            # Need to distinguish between client-provided `nil`
            # and nothing-at-all
            is_present, value = arg_to_value(graphql_object, arg_defn.type, arg.value)
            if is_present
              # This doesn't apply to directives, which are legacy
              # Can remove this when Skip and Include use classes or something.
              if graphql_object
                value = arg_defn.prepare_value(graphql_object, value)
              end
              kwarg_arguments[arg_defn.keyword] = value
            end
          end
          arg_owner.arguments.each do |name, arg_defn|
            if arg_defn.default_value? && !kwarg_arguments.key?(arg_defn.keyword)
              kwarg_arguments[arg_defn.keyword] = arg_defn.default_value
            end
          end
          kwarg_arguments
        end

        # Get a Ruby-ready value from a client query.
        # @param graphql_object [Object] The owner of the field whose argument this is
        # @param arg_type [Class, GraphQL::Schema::NonNull, GraphQL::Schema::List]
        # @param ast_value [GraphQL::Language::Nodes::VariableIdentifier, String, Integer, Float, Boolean]
        # @return [Array(is_present, value)]
        def arg_to_value(graphql_object, arg_type, ast_value)
          if ast_value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
            # If it's not here, it will get added later
            if query.variables.key?(ast_value.name)
              return true, query.variables[ast_value.name]
            else
              return false, nil
            end
          elsif arg_type.is_a?(GraphQL::Schema::NonNull)
            arg_to_value(graphql_object, arg_type.of_type, ast_value)
          elsif arg_type.is_a?(GraphQL::Schema::List)
            # Treat a single value like a list
            arg_value = Array(ast_value)
            list = []
            arg_value.map do |inner_v|
              _present, value = arg_to_value(graphql_object, arg_type.of_type, inner_v)
              list << value
            end
            return true, list
          elsif arg_type.is_a?(Class) && arg_type < GraphQL::Schema::InputObject
            # For these, `prepare` is applied during `#initialize`.
            # Pass `nil` so it will be skipped in `#arguments`.
            # What a mess.
            args = arguments(nil, arg_type, ast_value)
            # We're not tracking defaults_used, but for our purposes
            # we compare the value to the default value.
            return true, arg_type.new(ruby_kwargs: args, context: context, defaults_used: nil)
          else
            flat_value = flatten_ast_value(ast_value)
            return true, arg_type.coerce_input(flat_value, context)
          end
        end

        def flatten_ast_value(v)
          case v
          when GraphQL::Language::Nodes::Enum
            v.name
          when GraphQL::Language::Nodes::InputObject
            h = {}
            v.arguments.each do |arg|
              h[arg.name] = flatten_ast_value(arg.value)
            end
            h
          when Array
            v.map { |v2| flatten_ast_value(v2) }
          when GraphQL::Language::Nodes::VariableIdentifier
            flatten_ast_value(query.variables[v.name])
          else
            v
          end
        end

        def write_in_response(path, value, propagating_nil: false)
          if dead_path?(path)
            return
          else
            if value.is_a?(GraphQL::ExecutionError) || (value.is_a?(Array) && value.any? && value.all? { |v| v.is_a?(GraphQL::ExecutionError)})
              Array(value).each do |v|
                context.errors << v
              end
              write_in_response(path, nil, propagating_nil: propagating_nil)
              add_dead_path(path)
            elsif value.is_a?(GraphQL::InvalidNullError)
              schema.type_error(value, context)
              write_in_response(path, nil, propagating_nil: true)
              add_dead_path(path)
            elsif value.nil? && path.any? && type_at(path).non_null?
              # This nil is invalid, try writing it at the previous spot
              propagate_path = path[0..-2]
              write_in_response(propagate_path, value, propagating_nil: true)
              add_dead_path(propagate_path)
            else
              @response.write(path, value, propagating_nil: propagating_nil)
            end
          end
        end

        # To propagate nulls, we have to know what the field type was
        # at previous parts of the response.
        # This hash matches the response
        def type_at(path)
          t = @types_at_paths
          path.each do |part|
            if part.is_a?(Integer)
              part = 0
            end
            t = t[part] || (raise("Invariant: #{part.inspect} not found in #{t}"))
          end
          t = t[:__type]
          t
        end

        def set_type_at_path(path, type)
          types = @types_at_paths
          path.each do |part|
            if part.is_a?(Integer)
              part = 0
            end

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
      end
    end
  end
end
