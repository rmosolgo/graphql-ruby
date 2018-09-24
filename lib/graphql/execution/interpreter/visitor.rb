# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # The visitor itself is stateless,
      # it delegates state to the `trace`
      #
      # It sets up a lot of context with `push` and `pop`
      # to keep noise out of the Ruby backtrace.
      #
      # I think it would be even better if we could somehow make
      # `continue_field` not recursive. "Trampolining" it somehow.
      class Visitor

        class Bounce
          def initialize(object, method, *arguments)
            @object = object
            @method = method
            @arguments = arguments
          end

          def continue
            @object.send(@method, *@arguments)
          end
        end

        def visit(trace)
          path = []
          root_operation = trace.query.selected_operation
          root_type = trace.schema.root_type_for_operation(root_operation.operation_type || "query")
          root_type = root_type.metadata[:type_class]
          object_proxy = root_type.authorized_new(trace.query.root_value, trace.query.context)

          res = evaluate_selections(path, object_proxy, root_type, root_operation.selections, trace)
          trampoline(res)
        end

        def trampoline(result)
          bounces = [result]
          while bounces.any?
            next_bounce = bounces.shift
            case next_bounce
            when Bounce
              bounces << next_bounce.continue
            when Array
              bounces.concat(next_bounce)
            when GraphQL::Execution::Lazy
              bounces << next_bounce.value
            else
              # nothing
            end
          end
        end

        def gather_selections(selections, owner_type, trace, selections_by_name)
          selections.each do |node|
            case node
            when GraphQL::Language::Nodes::Field
              if passes_skip_and_include?(trace, node)
                response_key = node.alias || node.name
                s = selections_by_name[response_key] ||= []
                s << node
              end
            when GraphQL::Language::Nodes::InlineFragment
              if passes_skip_and_include?(trace, node)
                include_fragmment = if node.type
                  type_defn = trace.schema.types[node.type.name]
                  type_defn = type_defn.metadata[:type_class]
                  possible_types = trace.schema.possible_types(type_defn).map { |t| t.metadata[:type_class] }
                  possible_types.include?(owner_type)
                else
                  true
                end
                if include_fragmment
                  gather_selections(node.selections, owner_type, trace, selections_by_name)
                end
              end
            when GraphQL::Language::Nodes::FragmentSpread
              if passes_skip_and_include?(trace, node)
                fragment_def = trace.query.fragments[node.name]
                type_defn = trace.schema.types[fragment_def.type.name]
                type_defn = type_defn.metadata[:type_class]
                possible_types = trace.schema.possible_types(type_defn).map { |t| t.metadata[:type_class] }
                if possible_types.include?(owner_type)
                  gather_selections(fragment_def.selections, owner_type, trace, selections_by_name)
                end
              end
            else
              raise "Invariant: unexpected selection class: #{node.class}"
            end
          end
        end

        def evaluate_selections(path, owner_object, owner_type, selections, trace)
          selections_by_name = {}
          owner_type = resolve_if_late_bound_type(owner_type, trace)
          gather_selections(selections, owner_type, trace, selections_by_name)
          selections_by_name.map do |result_name, fields|
            # Maybe overriden with dynamic_field object
            object = owner_object
            ast_node = fields.first
            field_name = ast_node.name
            field_defn = owner_type.fields[field_name]
            is_introspection = false
            if field_defn.nil?
              field_defn = if owner_type == trace.schema.query.metadata[:type_class] && (entry_point_field = trace.schema.introspection_system.entry_point(name: field_name))
                is_introspection = true
                entry_point_field.metadata[:type_class]
              elsif (dynamic_field = trace.schema.introspection_system.dynamic_field(name: field_name))
                is_introspection = true
                dynamic_field.metadata[:type_class]
              else
                raise "Invariant: no field for #{owner_type}.#{field_name}"
              end
            end

            # TODO: this support is required for introspection types.
            if !field_defn.respond_to?(:extras)
              field_defn = field_defn.metadata[:type_class]
            end

            return_type = resolve_if_late_bound_type(field_defn.type, trace)

            # TODO no new object?
            next_path = path + [result_name]
            trace.query.trace("execute_field", {trace: trace}) do
              if is_introspection
                object = field_defn.owner.authorized_new(object, trace.context)
              end

              kwarg_arguments = trace.arguments(field_defn, ast_node)
              # TODO: very shifty that these cached Hashes are being modified
              if field_defn.extras.include?(:ast_node)
                kwarg_arguments[:ast_node] = ast_node
              end
              if field_defn.extras.include?(:execution_errors)
                kwarg_arguments[:execution_errors] = ExecutionErrors.new(trace.context, ast_node, next_path)
              end

              app_result = field_defn.resolve_field_2(object, kwarg_arguments, trace.context)

              trace.after_lazy(app_result) do |inner_trace, inner_result|
                if continue_value(next_path, inner_result, field_defn, return_type, ast_node, inner_trace)
                  # TODO will this be a perf issue for scalar fields?
                  next_selections = fields.map(&:selections).inject(&:+)
                  continue_field(next_path, inner_result, field_defn, return_type, ast_node, inner_trace, next_selections)
                end
              end
            end
          end
        end

        def continue_value(path, value, field, as_type, ast_node, trace)
          if value.nil? || value.is_a?(GraphQL::ExecutionError)
            if value.nil?
              if as_type.non_null?
                err = GraphQL::InvalidNullError.new(field.owner, field, value)
                trace.write(path, err, field, propagating_nil: true)
              else
                trace.write(path, nil, field)
              end
            else
              value.path ||= path
              value.ast_node ||= ast_node
              trace.write(path, value, field, propagating_nil: as_type.non_null?)
            end
            false
          elsif value.is_a?(Array) && value.all? { |v| v.is_a?(GraphQL::ExecutionError) }
            value.each do |v|
              v.path ||= path
              v.ast_node ||= ast_node
            end
            trace.write(path, value, field, propagating_nil: as_type.non_null?)
            false
          elsif GraphQL::Execution::Execute::SKIP == value
            false
          else
            true
          end
        end

        def continue_field(path, value, field, type, ast_node, trace, next_selections)
          type = resolve_if_late_bound_type(type, trace)

          case type.kind
          when TypeKinds::SCALAR, TypeKinds::ENUM
            r = type.coerce_result(value, trace.query.context)
            trace.write(path, r, field)
          when TypeKinds::UNION, TypeKinds::INTERFACE
            obj_type = trace.schema.resolve_type(type, value, trace.query.context)
            obj_type = obj_type.metadata[:type_class]
            Bounce.new(self, :continue_field, path, value, field, obj_type, ast_node, trace, next_selections)
          when TypeKinds::OBJECT
            object_proxy = type.authorized_new(value, trace.query.context)
            trace.after_lazy(object_proxy) do |inner_trace, inner_object|
              if continue_value(path, inner_object, field, type, ast_node, inner_trace)
                inner_trace.write(path, {}, field)
                Bounce.new(self, :evaluate_selections, path, inner_object, type, next_selections, inner_trace)
              end
            end
          when TypeKinds::LIST
            trace.write(path, [], field)
            inner_type = type.of_type
            value.each_with_index.map do |inner_value, idx|
              # TODO no new object?
              next_path = path + [idx]
              trace.after_lazy(inner_value) do |inner_trace, inner_inner_value|
                if continue_value(next_path, inner_inner_value, field, inner_type, ast_node, inner_trace)
                  Bounce.new(self, :continue_field, next_path, inner_inner_value, field, inner_type, ast_node, inner_trace, next_selections)
                end
              end
            end
          when TypeKinds::NON_NULL
            inner_type = type.of_type
            # Don't `set_type_at_path` because we want the static type,
            # we're going to use that to determine whether a `nil` should be propagated or not.
            Bounce.new(self, :continue_field, path, value, field, inner_type, ast_node, trace, next_selections)
          else
            raise "Invariant: Unhandled type kind #{type.kind} (#{type})"
          end
        end

        def passes_skip_and_include?(trace, node)
          # TODO call out to directive here
          node.directives.each do |dir|
            dir_defn = trace.schema.directives.fetch(dir.name)
            if dir.name == "skip" && trace.arguments(dir_defn, dir)[:if] == true
              return false
            elsif dir.name == "include" && trace.arguments(dir_defn, dir)[:if] == false
              return false
            end
          end
          true
        end

        def resolve_if_late_bound_type(type, trace)
          if type.is_a?(GraphQL::Schema::LateBoundType)
            trace.query.warden.get_type(type.name).metadata[:type_class]
          else
            type
          end
        end
      end
    end
  end
end
