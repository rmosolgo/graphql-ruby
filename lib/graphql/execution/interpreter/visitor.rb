# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # The visitor itself is stateless,
      # it delegates state to the `trace`
      class Visitor < GraphQL::Language::Visitor
        extend Forwardable
        def_delegators :@trace, :query, :schema, :context
        attr_reader :trace

        def initialize(document, trace:)
          super(document)
          @trace = trace
        end

        def on_operation_definition(node, _parent)
          if node == query.selected_operation
            root_type = schema.root_type_for_operation(node.operation_type || "query")
            root_type = root_type.metadata[:type_class]
            object_proxy = root_type.authorized_new(query.root_value, query.context)
            trace.with_type(root_type) do
              trace.with_object(object_proxy) do
                super
              end
            end
          end
        end

        def on_fragment_definition(node, parent)
          # Do nothing, not executable
        end

        def on_fragment_spread(node, _parent)
          wrap_with_directives(node, _parent) do |node, _parent|
            fragment_def = query.fragments[node.name]
            type_defn = schema.types[fragment_def.type.name]
            type_defn = type_defn.metadata[:type_class]
            possible_types = schema.possible_types(type_defn).map { |t| t.metadata[:type_class] }
            if possible_types.include?(trace.types.last)
              fragment_def.selections.each do |selection|
                visit_node(selection, fragment_def)
              end
            end
            super
          end
        end

        def on_inline_fragment(node, _parent)
          wrap_with_directives(node, _parent) do |node, _parent|
            if node.type
              type_defn = schema.types[node.type.name]
              type_defn = type_defn.metadata[:type_class]
              possible_types = schema.possible_types(type_defn).map { |t| t.metadata[:type_class] }
              if possible_types.include?(trace.types.last)
                super
              end
            else
              super
            end
          end
        end

        # TODO: make sure this can support what we need to do
        # - conditionally skip continuation
        # - skip continuation; resume later
        # - continue on a different AST (turning graphql into JSON API)
        # - Add the result of the field to query.variables
        def wrap_with_directives(node, parent)
          # TODO call out to directive here
          node.directives.each do |dir|
            dir_defn = schema.directives.fetch(dir.name)
            if dir.name == "skip" && trace.arguments(dir_defn, dir)[:if] == true
              return
            elsif dir.name == "include" && trace.arguments(dir_defn, dir)[:if] == false
              return
            end
          end
          yield(node, parent)
        end

        def on_field(node, parent)
          wrap_with_directives(node, parent) do |node, parent|
            field_name = node.name
            field_defn = trace.types.last.unwrap.fields[field_name]
            is_introspection = false
            if field_defn.nil?
              field_defn = if trace.types.last == schema.query.metadata[:type_class] && (entry_point_field = schema.introspection_system.entry_point(name: field_name))
                is_introspection = true
                entry_point_field.metadata[:type_class]
              elsif (dynamic_field = schema.introspection_system.dynamic_field(name: field_name))
                is_introspection = true
                dynamic_field.metadata[:type_class]
              else
                raise "Invariant: no field for #{trace.types.last}.#{field_name}"
              end
            end

            trace.with_path(node.alias || node.name) do
              trace.with_type(field_defn.type) do
                # TODO: check if this field was resolved by some other part of the query.
                # Don't re-evaluate it if so?
                object = trace.objects.last
                if is_introspection
                  object = field_defn.owner.authorized_new(object, context)
                end
                kwarg_arguments = trace.arguments(field_defn, node)
                # TODO: very shifty that these cached Hashes are being modified
                if field_defn.extras.include?(:ast_node)
                  kwarg_arguments[:ast_node] = node
                end
                if field_defn.extras.include?(:execution_errors)
                  kwarg_arguments[:execution_errors] = ExecutionErrors.new(context, node, trace.path.dup)
                end

                result = field_defn.resolve_field_2(object, kwarg_arguments, context)

                trace.after_lazy(result) do |trace, inner_result|
                  trace.visitor.continue_field(field_defn.type, inner_result, node) do |final_trace|
                    final_trace.debug("Visiting children at #{final_trace.path}")
                    final_trace.visitor.on_abstract_node(node, parent)
                  end
                end
              end
            end
          end

          return node, parent
        end

        def continue_value(value, ast_node)
          if value.nil?
            trace.write(nil)
            false
          elsif value.is_a?(GraphQL::ExecutionError)
            # TODO this probably needs the node added somewhere
            value.path ||= trace.path.dup
            value.ast_node ||= ast_node
            context.errors << value
            trace.write(nil)
            false
          elsif GraphQL::Execution::Execute::SKIP == value
            false
          else
            true
          end
        end

        def continue_field(type, value, ast_node)
          if !continue_value(value, ast_node)
            return
          end

          if type.is_a?(GraphQL::Schema::LateBoundType)
            type = query.warden.get_type(type.name).metadata[:type_class]
          end

          case type.kind
          when TypeKinds::SCALAR, TypeKinds::ENUM
            r = type.coerce_result(value, query.context)
            trace.debug("Writing #{r.inspect} at #{trace.path}")
            trace.write(r)
          when TypeKinds::UNION, TypeKinds::INTERFACE
            obj_type = schema.resolve_type(type, value, query.context)
            obj_type = obj_type.metadata[:type_class]
            continue_field(obj_type, value, ast_node) { |t| yield(t) }
          when TypeKinds::OBJECT
            object_proxy = type.authorized_new(value, query.context)
            trace.after_lazy(object_proxy) do |inner_trace, inner_obj|
              if inner_trace.visitor.continue_value(inner_obj, ast_node)
                inner_trace.write({})
                inner_trace.with_type(type) do
                  inner_trace.with_object(inner_obj) do
                    yield(inner_trace)
                  end
                end
              end
            end
          when TypeKinds::LIST
            trace.write([])
            inner_type = type.of_type
            value.each_with_index.map do |inner_value, idx|
              trace.with_path(idx) do
                trace.after_lazy(inner_value) do |inner_trace, inner_v|
                  trace.with_type(inner_type) do
                    inner_trace.visitor.continue_field(inner_type, inner_v, ast_node) { |t| yield(t) }
                  end
                end
              end
            end
          when TypeKinds::NON_NULL
            continue_field(type.of_type, value, ast_node) { |t| yield(t) }
          else
            raise "Invariant: Unhandled type kind #{type.kind} (#{type})"
          end
        end
      end
    end
  end
end
