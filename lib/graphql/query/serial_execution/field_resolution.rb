# frozen_string_literal: true
module GraphQL
  class Query
    class SerialExecution
      class FieldResolution
        attr_reader :irep_node, :parent_type, :target, :field, :arguments, :query

        def initialize(selection, parent_type, target, query_ctx)
          @irep_node = selection
          @selection = selection
          @parent_type = parent_type
          @target = target
          @query = query_ctx.query
          @field = irep_node.definition
          @field_ctx = query_ctx.spawn_child(
            key: irep_node.name,
            object: target,
            irep_node: irep_node,
          )
          @arguments = @query.arguments_for(irep_node, @field)
        end

        def result
          result_name = irep_node.name
          raw_value = get_raw_value
          if raw_value.is_a?(GraphQL::Execution::Execute::Skip)
            {}
          else
            { result_name => get_finished_value(raw_value) }
          end
        end

        # GraphQL::Batch depends on this
        def execution_context
          @field_ctx
        end

        private

        # After getting the value from the field's resolve method,
        # continue by "finishing" the value, eg. executing sub-fields or coercing values
        def get_finished_value(raw_value)
          case raw_value
          when GraphQL::ExecutionError
            raw_value.ast_node = @field_ctx.ast_node
            raw_value.path = @field_ctx.path
            @query.context.errors.push(raw_value)
          when Array
            list_errors = raw_value.each_with_index.select { |value, _| value.is_a?(GraphQL::ExecutionError) }
            if list_errors.any?
              list_errors.each do |error, index|
                error.ast_node = @field_ctx.ast_node
                error.path = @field_ctx.path + [index]
                @query.context.errors.push(error)
              end
            end
          end

          begin
            GraphQL::Query::SerialExecution::ValueResolution.resolve(
              parent_type,
              field,
              field.type,
              raw_value,
              @selection,
              @field_ctx,
            )
          rescue GraphQL::Query::Executor::PropagateNull
            if field.type.kind.non_null?
              raise
            else
              nil
            end
          end
        end

        # Get the result of:
        # - Any middleware on this schema
        # - The field's resolve method
        # If the middleware chain returns a GraphQL::ExecutionError, its message
        # is added to the "errors" key.
        def get_raw_value
          begin
            @field_ctx.schema.middleware.invoke([parent_type, target, field, arguments, @field_ctx])
          rescue GraphQL::ExecutionError => err
            err
          end
        end
      end
    end
  end
end
