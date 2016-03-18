module GraphQL
  class Query
    class SerialExecution
      class FieldResolution
        attr_reader :ast_node, :parent_type, :target, :execution_context, :field, :arguments

        def initialize(ast_node, parent_type, target, execution_context)
          @ast_node = ast_node
          @parent_type = parent_type
          @target = target
          @execution_context = execution_context
          @field =  execution_context.get_field(parent_type, ast_node.name)
          if @field.nil?
            raise("No field found on #{parent_type.name} '#{parent_type}' for '#{ast_node.name}'")
          end
          @arguments = GraphQL::Query::LiteralInput.from_arguments(
            ast_node.arguments,
            field.arguments,
            execution_context.query.variables
          )
        end

        def result
          result_name = ast_node.alias || ast_node.name
          raw_value = begin
            get_raw_value
          rescue GraphQL::ExecutionError => err
            err
          end
          { result_name => get_finished_value(raw_value) }
        end

        private

        # After getting the value from the field's resolve method,
        # continue by "finishing" the value, eg. executing sub-fields or coercing values
        def get_finished_value(raw_value)
          if raw_value.is_a?(GraphQL::ExecutionError)
            raw_value.ast_node = ast_node
            execution_context.add_error(raw_value)
          end

          strategy_class = GraphQL::Query::SerialExecution::ValueResolution.get_strategy_for_kind(field.type.kind)
          result_strategy = strategy_class.new(raw_value, field.type, target, parent_type, ast_node, execution_context)
          result_strategy.result
        end


        # Get the result of:
        # - Any middleware on this schema
        # - The field's resolve method
        def get_raw_value
          steps = execution_context.query.schema.middleware + [get_middleware_proc_from_field_resolve]
          chain = GraphQL::Schema::MiddlewareChain.new(
            steps: steps,
            arguments: [parent_type, target, field, arguments, execution_context.query.context]
          )
          value = chain.call
          raise value if value.instance_of?(GraphQL::ExecutionError)
          value
        end


        # Execute the field's resolve method
        # @return [Proc] suitable to be the last step in a middleware chain
        def get_middleware_proc_from_field_resolve
          -> (_parent_type, parent_object, field_definition, field_args, context, _next) {
            context.ast_node = ast_node
            value = field_definition.resolve(parent_object, field_args, context)
            context.ast_node = nil
            value
          }
        end
      end
    end
  end
end
