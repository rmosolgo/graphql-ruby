module GraphQL
  class Query
    class SerialExecution
      class SelectionResolution
        attr_reader :target, :type, :irep_node, :execution_context

        def initialize(target, type, irep_node, execution_context)
          @target = target
          @type = type
          @irep_node = irep_node
          @execution_context = execution_context
        end

        def result
          irep_node.children.each_with_object({}) do |(name, irep_node), memo|
            if GraphQL::Execution::DirectiveChecks.include?(irep_node, execution_context.query) && applies_to_type?(irep_node, type, target)
              field_result = execution_context.strategy.field_resolution.new(
                irep_node,
                type,
                target,
                execution_context
              ).result
              memo.merge!(field_result)
            end
          end
        end

        private

        def applies_to_type?(irep_node, type, target)
          irep_node.definitions.any? { |child_type, field_defn|
            GraphQL::Execution::Typecast.compatible?(target, child_type, type, execution_context.query.context)
          }
        end
      end
    end
  end
end
