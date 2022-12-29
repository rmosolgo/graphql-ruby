module GraphQL
  module Execution
    class MinimalInterpreter
      module Underscore
        refine String do
          def underscore
            if match?(/\A[a-z_]+\Z/)
              return self
            end
            string = self.dup

            string.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2') # URLDecoder -> URL_Decoder
            string.gsub!(/([a-z\d])([A-Z])/,'\1_\2')     # someThing -> some_Thing
            string.downcase!

            string
          end
        end
      end

      using Underscore

      class << self
        def use(schema_defn)
          schema_defn.execution_engine(GraphQL::Execution::MinimalInterpreter)
        end

        # @param schema [GraphQL::Schema]
        # @param queries [Array<GraphQL::Query, Hash>]
        # @param context [Hash]
        # @return [Array<Hash>] One result per query
        def run_all(schema, query_options, context: {}, **_kwargs)
          queries = query_options.map do |opts|
            case opts
            when Hash
              GraphQL::Query.new(schema, nil, **opts)
            when GraphQL::Query
              opts
            else
              raise "Expected Hash or GraphQL::Query, not #{opts.class} (#{opts.inspect})"
            end
          end

          queries.map { |query| GraphQL::Query::Result.new(query: query, values: run(schema, query, context)) }
        end

        def run(schema, query, context)
          root_operation = query.selected_operation
          root_op_type = root_operation.operation_type || "query"
          root_type = schema.root_type_for_operation(root_op_type)
          object = root_type.new(query.root_value, query.context)

          operation = query.selected_operation
          data = run_node(schema, query, context, operation, root_type, object)

          {"data" => data, "errors" => query.static_errors.map(&:to_h)}
        end

        private

        def run_node(schema, query, context, node, current_type, object)
          selections = gather_selections(current_type, node.selections, query)

          selections.each_with_object({}) do |selection, data|
            field = current_type.fields(context)[selection.name]

            field_object =
              if field
                object
              else
                field = schema.introspection_system.dynamic_field(name: selection.name)
                field.owner.authorized_new(object, query.context)
              end

            field_type = if field.type.non_null?
              is_not_null = true
              field.type.of_type
            else
              is_not_null = false
              field.type
            end

            arguments = arguments_for(selection, query, context)
            value = resolve_value(schema, selection, field_object, arguments)

            case field_type.kind.name
            when 'SCALAR', "ENUM"
              # puts "selection #{selection.name} is_not_null #{is_not_null} value #{value.inspect}"
              if value.nil? && is_not_null
                error = InvalidNullError.new(current_type, field, value)
                query.context.errors << error
                data[selection.name] = nil
                raise error
              else
                data[selection.name] = field_type.coerce_result(value, query.context)
              end
            when "UNION", "INTERFACE"
              # TODO: implement
            when "OBJECT"
              # puts "selection #{selection.name} is_not_null #{is_not_null} value #{value.inspect}"
              after_lazy(value, schema) do |resolved_lazy_value|
                nested_object_proxy = field_type.new(resolved_lazy_value, query.context)
                data[selection.name] =
                  begin
                    run_node(schema, query, context, selection, field_type, nested_object_proxy)
                  rescue InvalidNullError
                    nil
                  end
              end
            when "LIST"
              inner_type = field_type.of_type.non_null? ? field_type.of_type.of_type : field_type.of_type

              begin
                data[selection.name] = value&.map do |element|
                  case inner_type.kind.name
                  when "UNION"
                    element_type = inner_type.resolve_type(element, query.context)
                    element_object_proxy = element_type.new(element, query.context)
                    run_node(schema, query, context, selection, element_type, element_object_proxy)
                  when "SCALAR", "ENUM"
                    inner_type.coerce_result(element, query.context)
                  else
                    element_object_proxy = inner_type.new(element, query.context)
                    run_node(schema, query, context, selection, inner_type, element_object_proxy)
                  end
                end
              end
            end
          end
        end

        def gather_selections(type, selections, query)
          selections.each_with_object([]) do |selection, result|
            case selection
            when GraphQL::Language::Nodes::InlineFragment
              if selection.type.nil? || selection.type.name == type.graphql_name
                selection.selections.each do |fragment_selection|
                  result << fragment_selection
                end
              end
            when GraphQL::Language::Nodes::FragmentSpread
              query.fragments[selection.name].selections.each { |selection| result << selection }
            else
              result << selection
            end
          end
        end

        def arguments_for(selection, query, context)
          selection.arguments.map do |argument|
            value = if argument.value.is_a?(Array)
              argument.value.map { |value| resolve_argument_value(value, query) }
            else
              resolve_argument_value(argument.value, query)
            end

            [argument.name.to_sym, value]
          end.to_h
        end

        def resolve_value(schema, selection, field_object, arguments)
          method_name = selection.name.underscore.to_sym

          after_lazy(field_object, schema) do |object|
            if object&.respond_to?(method_name)
              object&.send(method_name, **arguments)
            elsif object.respond_to?(:object)
              after_lazy(object.object, schema) { |object| object&.send(method_name, **arguments) }
            else
              # TODO: implement
            end
          end
        end

        def resolve_argument_value(value, query)
          if value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
            query.variables.fetch(value.name)
          else
            value
          end
        end

        def after_lazy(object, schema)
          if schema.lazy?(object)
            yield object.value
          else
            yield object
          end
        end
      end
    end
  end
end
