module GraphQL
  class Query
    class SerialExecution
      class FieldResolution
        attr_reader :ast_node, :parent_type, :target, :query, :execution_strategy, :field, :arguments

        def initialize(ast_node, parent_type, target, query, execution_strategy)
          @ast_node = ast_node
          @parent_type = parent_type
          @target = target
          @query = query
          @execution_strategy = execution_strategy
          @field = query.schema.get_field(parent_type, ast_node.name) || raise("No field found on #{parent_type.name} '#{parent_type}' for '#{ast_node.name}'")
          @arguments = GraphQL::Query::LiteralInput.from_arguments(ast_node.arguments, field.arguments, query.variables)
        end

        def result
          result_name = ast_node.alias || ast_node.name
          result_value = begin
            get_finished_value(get_raw_value)
          rescue GraphQL::ExecutionError => err
            err.ast_node = ast_node
            query.context.errors << err
            nil
          end
          { result_name => result_value  }
        end

        private

        # After getting the value from the field's resolve method,
        # continue by "finishing" the value, eg. executing sub-fields or coercing values
        def get_finished_value(raw_value)
          raise raw_value if raw_value.instance_of?(GraphQL::ExecutionError)

          strategy_class = GraphQL::Query::SerialExecution::ValueResolution.get_strategy_for_kind(field.type.kind)
          result_strategy = strategy_class.new(raw_value, field.type, target, parent_type, ast_node, query, execution_strategy)
          result_strategy.result
        end


        # Get the result of:
        # - Any middleware on this schema
        # - The field's resolve method
        def get_raw_value
          steps = query.schema.middleware + [get_middleware_proc_from_field_resolve]
          chain = GraphQL::Schema::MiddlewareChain.new(
            steps: steps,
            arguments: [parent_type, target, field, arguments, query.context]
          )
          chain.call
        end


        # Execute the field's resolve method
        # then handle the DEFAULT_RESOLVE
        # @return [Proc] suitable to be the last step in a middleware chain
        def get_middleware_proc_from_field_resolve
          -> (_parent_type, parent_object, field_definition, field_args, context, _next) {
            context.ast_node = ast_node
            value = field_definition.resolve(parent_object, field_args, context)
            context.ast_node = nil

            if value == GraphQL::Query::DEFAULT_RESOLVE
              begin
                value = target.public_send(ast_node.name)
              rescue NoMethodError => err
                raise("Couldn't resolve field '#{ast_node.name}' to #{parent_object.class} '#{parent_object}' (resulted in #{err})")
              end
            end

            value
          }
        end
      end
    end
  end
end
