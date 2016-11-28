module GraphQL
  class Query
    class SerialExecution
      class FieldResolution
        attr_reader :irep_node, :parent_type, :target, :field, :arguments, :query

        def initialize(selection, parent_type, target, query_ctx)
          @irep_node = selection.irep_node
          @selection = selection
          @parent_type = parent_type
          @target = target
          @query = query_ctx.query
          @field = @query.get_field(parent_type, irep_node.definition_name)
          @field_ctx = query_ctx.spawn(
            key: irep_node.name,
            selection: selection,
            parent_type: parent_type,
            field: field,
          )
          @arguments = @query.arguments_for(irep_node, @field)
        end

        def result
          result_name = irep_node.name
          raw_value = get_raw_value
          { result_name => get_finished_value(raw_value) }
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

          GraphQL::Query::SerialExecution::ValueResolution.resolve(
            parent_type,
            field,
            field.type,
            raw_value,
            @selection,
            @field_ctx,
          )
        end

        # Get the result of:
        # - Any middleware on this schema
        # - The field's resolve method
        # If the middleware chain returns a GraphQL::ExecutionError, its message
        # is added to the "errors" key.
        def get_raw_value
          middlewares = @query.schema.middleware

          resolve_arguments = [parent_type, target, field, arguments, @field_ctx]

          begin
            # only run a middleware chain if there are any middleware
            if middlewares.any?
              chain = GraphQL::Schema::MiddlewareChain.new(
                steps: middlewares + [FieldResolveStep],
                arguments: resolve_arguments
              )
              chain.call
            else
              FieldResolveStep.call(*resolve_arguments)
            end
          rescue GraphQL::ExecutionError => err
            err
          end
        end

        # A `.call`-able suitable to be the last step in a middleware chain
        module FieldResolveStep
          # Execute the field's resolve method
          def self.call(_parent_type, parent_object, field_definition, field_args, context, _next = nil)
            field_definition.resolve(parent_object, field_args, context)
          end
        end
      end
    end
  end
end
