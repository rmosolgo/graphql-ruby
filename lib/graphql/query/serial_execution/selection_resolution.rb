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
            if included_by_directives?(irep_node, execution_context.query) && applies_to_type?(irep_node, type, target)
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

        def included_by_directives?(irep_node, query)
          GraphQL::Query::DirectiveResolution.include_node?(irep_node, query)
        end

        def applies_to_type?(irep_node, type, target)
          irep_node.on_types.any? { |child_type|
            GraphQL::Query::TypeResolver.new(target, child_type, type, execution_context.query.context).type
          }
        end
      end
    end
  end
end
