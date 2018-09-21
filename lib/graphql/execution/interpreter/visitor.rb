# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # The visitor itself is stateless,
      # it delegates state to the `trace`
      class Visitor
        @@depth = 0
        @@has_been_1 = false
        def visit(trace)
          root_operation = trace.query.selected_operation
          root_type = trace.schema.root_type_for_operation(root_operation.operation_type || "query")
          root_type = root_type.metadata[:type_class]
          object_proxy = root_type.authorized_new(trace.query.root_value, trace.query.context)

          trace.with_type(root_type) do
            trace.with_object(object_proxy) do
              evaluate_selections(root_operation.selections, trace)
            end
          end
        end

        def gather_selections(selections, trace, selections_by_name)
          selections.each do |node|
            case node
            when GraphQL::Language::Nodes::Field
              wrap_with_directives(trace, node) do
                response_key = node.alias || node.name
                s = selections_by_name[response_key] ||= []
                s << node
              end
            when GraphQL::Language::Nodes::InlineFragment
              wrap_with_directives(trace, node) do
                include_fragmment = if node.type
                  type_defn = trace.schema.types[node.type.name]
                  type_defn = type_defn.metadata[:type_class]
                  possible_types = trace.schema.possible_types(type_defn).map { |t| t.metadata[:type_class] }
                  owner_type = trace.types.last
                  possible_types.include?(owner_type)
                else
                  true
                end
                if include_fragmment
                  gather_selections(node.selections, trace, selections_by_name)
                end
              end
            when GraphQL::Language::Nodes::FragmentSpread
              wrap_with_directives(trace, node) do
                fragment_def = trace.query.fragments[node.name]
                type_defn = trace.schema.types[fragment_def.type.name]
                type_defn = type_defn.metadata[:type_class]
                possible_types = trace.schema.possible_types(type_defn).map { |t| t.metadata[:type_class] }
                owner_type = trace.types.last
                if possible_types.include?(owner_type)
                  gather_selections(fragment_def.selections, trace, selections_by_name)
                end
              end
            else
              raise "Invariant: unexpected selection class: #{node.class}"
            end
          end
        end

        def evaluate_selections(selections, trace)
          selections_by_name = {}
          gather_selections(selections, trace, selections_by_name)
          selections_by_name.each do |result_name, fields|
            owner_type = trace.types.last
            owner_type = resolve_if_late_bound_type(owner_type, trace)
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

            trace.fields.push(field_defn)
            trace.with_path(result_name) do
              trace.with_type(field_defn.type) do
                trace.query.trace("execute_field", {trace: trace}) do
                  object = trace.objects.last

                  if is_introspection
                    object = field_defn.owner.authorized_new(object, trace.context)
                  end

                  kwarg_arguments = trace.arguments(field_defn, ast_node)
                  # TODO: very shifty that these cached Hashes are being modified
                  if field_defn.extras.include?(:ast_node)
                    kwarg_arguments[:ast_node] = ast_node
                  end
                  if field_defn.extras.include?(:execution_errors)
                    kwarg_arguments[:execution_errors] = ExecutionErrors.new(trace.context, ast_node, trace.path.dup)
                  end

                  app_result = field_defn.resolve_field_2(object, kwarg_arguments, trace.context)
                  return_type = resolve_if_late_bound_type(field_defn.type, trace)

                  trace.after_lazy(app_result) do |inner_trace, inner_result|
                    if continue_value(inner_result, field_defn, return_type, ast_node, inner_trace)
                      continue_field(inner_result, field_defn, return_type, ast_node, inner_trace) do |final_trace|
                        all_selections = fields.map(&:selections).inject(&:+)
                        evaluate_selections(all_selections, final_trace)
                      end
                    end
                  end
                  trace.fields.pop
                end
              end
            end
          end
        end

        def continue_value(value, field, as_type, ast_node, trace)
          if value.nil? || value.is_a?(GraphQL::ExecutionError)
            if value.nil?
              if as_type.non_null?
                err = GraphQL::InvalidNullError.new(field.owner, field, value)
                trace.write(err, propagating_nil: true)
              else
                trace.write(nil)
              end
            else
              value.path ||= trace.path.dup
              value.ast_node ||= ast_node
              trace.write(value, propagating_nil: as_type.non_null?)
            end
            false
          elsif value.is_a?(Array) && value.all? { |v| v.is_a?(GraphQL::ExecutionError) }
            value.each do |v|
              v.path ||= trace.path.dup
              v.ast_node ||= ast_node
            end
            trace.write(value, propagating_nil: as_type.non_null?)
            false
          elsif GraphQL::Execution::Execute::SKIP == value
            false
          else
            true
          end
        end

        def continue_field(value, field, type, ast_node, trace)
          type = resolve_if_late_bound_type(type, trace)

          case type.kind
          when TypeKinds::SCALAR, TypeKinds::ENUM
            r = type.coerce_result(value, trace.query.context)
            trace.write(r)
          when TypeKinds::UNION, TypeKinds::INTERFACE
            obj_type = trace.schema.resolve_type(type, value, trace.query.context)
            obj_type = obj_type.metadata[:type_class]
            trace.with_type(obj_type) do
              continue_field(value, field, obj_type, ast_node, trace) { |t| yield(t) }
            end
          when TypeKinds::OBJECT
            object_proxy = type.authorized_new(value, trace.query.context)
            trace.after_lazy(object_proxy) do |inner_trace, inner_object|
              inner_trace.write({})
              inner_trace.with_object(inner_object) do
                yield(inner_trace)
              end
            end
          when TypeKinds::LIST
            trace.write([])
            inner_type = type.of_type
            value.each_with_index.each do |inner_value, idx|
              trace.with_path(idx) do
                trace.with_type(inner_type) do
                  trace.after_lazy(inner_value) do |inner_trace, inner_inner_value|
                    if continue_value(inner_inner_value, field, inner_type, ast_node, inner_trace)
                      continue_field(inner_inner_value, field, inner_type, ast_node, inner_trace) { |t| yield(t) }
                    end
                  end
                end
              end
            end
          when TypeKinds::NON_NULL
            inner_type = type.of_type
            trace.with_type(inner_type) do
              continue_field(value, field, inner_type, ast_node, trace) { |t| yield(t) }
            end
          else
            raise "Invariant: Unhandled type kind #{type.kind} (#{type})"
          end
        end

        def wrap_with_directives(trace, node)
          # TODO call out to directive here
          node.directives.each do |dir|
            dir_defn = trace.schema.directives.fetch(dir.name)
            if dir.name == "skip" && trace.arguments(dir_defn, dir)[:if] == true
              return
            elsif dir.name == "include" && trace.arguments(dir_defn, dir)[:if] == false
              return
            end
          end
          yield
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
