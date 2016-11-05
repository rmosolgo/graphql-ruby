module GraphQL
  class Query
    class SerialExecution
      class FieldResolution
        attr_reader :irep_node, :parent_type, :target, :execution_context, :field, :arguments

        def initialize(frame, parent_type, target, execution_context)
          @frame = frame
          @irep_node = frame.irep_node
          @parent_type = parent_type
          @target = target
          @execution_context = execution_context
          @field = execution_context.get_field(parent_type, irep_node)
          @arguments = execution_context.query.arguments_for(irep_node, @field)
        end

        def result
          result_name = irep_node.name
          raw_value = get_raw_value
          { result_name => get_finished_value(raw_value) }
        end

        private

        # After getting the value from the field's resolve method,
        # continue by "finishing" the value, eg. executing sub-fields or coercing values
        def get_finished_value(raw_value)
          case raw_value
          when GraphQL::ExecutionError
            @frame.add_error(raw_value)
          when Array
            list_errors = raw_value.each_with_index.select { |value, _| value.is_a?(GraphQL::ExecutionError) }
            if list_errors.any?
              list_errors.each do |error, index|
                error.ast_node = irep_node.ast_node
                error.path = irep_node.path + [index]
                execution_context.add_error(error)
              end
            end
          end

          begin
            GraphQL::Query::SerialExecution::ValueResolution.resolve(
              parent_type,
              field,
              field.type,
              raw_value,
              @frame,
              execution_context,
            )
          rescue GraphQL::InvalidNullError => err
            if field.type.kind.non_null?
              raise(err)
            else
              err.parent_error? || @frame.add_error(err)
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
          middlewares = execution_context.query.schema.middleware
          query_context = execution_context.query.context
          # setup
          query_context.irep_node = @irep_node

          resolve_arguments = [parent_type, target, field, arguments, query_context]

          resolve_value = begin
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
        ensure
          # teardown
          query_context.irep_node = nil
          resolve_value
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
