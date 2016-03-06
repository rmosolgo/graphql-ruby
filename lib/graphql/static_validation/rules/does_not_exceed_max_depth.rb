module GraphQL
  module StaticValidation
    class DoesNotExceedMaxDepth
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        max_allowed_depth = context.schema.max_depth
        return if max_allowed_depth.nil?

        visitor = context.visitor

        current_depth = 0
        already_exceeded_max_depth = false

        visitor[GraphQL::Language::Nodes::Field] << -> (node, parent) {
          if node.selections.any? && !already_exceeded_max_depth
            current_depth += 1
          elsif current_depth > max_allowed_depth
            already_exceeded_max_depth = true
            context.errors << message("Exceeds maximum query depth of #{max_allowed_depth}", node)
          end
        }

        visitor[GraphQL::Language::Nodes::Field].leave << -> (node, parent) {
          if node.selections.any? && current_depth > 0
            current_depth -= 1
          end
        }
      end
    end
  end
end
