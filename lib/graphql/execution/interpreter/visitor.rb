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
            @trace.result.ruby_value = object_proxy
            @trace.result.static_type = root_type
            @trace.result.dynamic_type = root_type
            @trace.result.write({})
            super
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
            owner_type = trace.response_nodes.last.dynamic_type
            if possible_types.include?(owner_type)
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
            owner_type = trace.response_nodes.last.dynamic_type.unwrap
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

            response_key = node.alias || node.name
            object = trace.response_nodes.last.ruby_value
            trace.within(response_key, node, field_defn.type) do |response_node|
              response_node.call_ruby_value do
                puts "Eval #{response_node.trace.path} (#{response_key}, #{response_node.ruby_value.inspect})"
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

                field_defn.resolve_field_2(object, kwarg_arguments, context)
              end

              response_node.after_lazy do
                continue_field(response_node) do
                  response_node.trace.visitor.on_abstract_node(node, parent)
                end
              end
            end
          end

          return node, parent
        end

        def continue_value(response_node)
          if response_node.ruby_value.nil?
            response_node.write(nil)
            false
          elsif response_node.ruby_value.is_a?(GraphQL::ExecutionError)
            value.path ||= response_node.trace.path.dup
            value.ast_node ||= response_node.ast_node
            context.errors << value
            response_node.write(nil)
            false
          elsif GraphQL::Execution::Execute::SKIP == response_node.ruby_value
            response_node.omitted = true
            false
          else
            true
          end
        end

        def continue_field(response_node)
          type = response_node.dynamic_type
          value = response_node.ruby_value
          ast_node = response_node.ast_node

          if !continue_value(response_node)
            return
          end

          if type.is_a?(GraphQL::Schema::LateBoundType)
            type = query.warden.get_type(type.name).metadata[:type_class]
          end

          case type.kind
          when TypeKinds::SCALAR, TypeKinds::ENUM
            r = type.coerce_result(value, query.context)
            response_node.write(r)
          when TypeKinds::UNION, TypeKinds::INTERFACE
            obj_type = schema.resolve_type(type, value, query.context)
            obj_type = obj_type.metadata[:type_class]
            response_node.dynamic_type = obj_type
            continue_field(response_node) { yield }
          when TypeKinds::OBJECT
            object_proxy = type.authorized_new(value, query.context)
            response_node.ruby_value = object_proxy
            response_node.write({})
            response_node.after_lazy do
              if continue_value(response_node)
                yield
              end
            end
          when TypeKinds::LIST
            response_node.write([])
            inner_type = response_node.dynamic_type.of_type
            response_node.ruby_value.each_with_index.each do |inner_value, idx|
              response_node.trace.within(idx, ast_node, inner_type) do |response_node|
                response_node.ruby_value = inner_value
                response_node.after_lazy do
                  continue_field(response_node) { yield }
                end
              end
            end
          when TypeKinds::NON_NULL
            response_node.dynamic_type = response_node.dynamic_type.of_type
            continue_field(response_node) { yield }
          else
            raise "Invariant: Unhandled type kind #{type.kind} (#{type})"
          end
        end
      end
    end
  end
end
