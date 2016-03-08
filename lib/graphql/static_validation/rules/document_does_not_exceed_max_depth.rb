module GraphQL
  module StaticValidation
    class DocumentDoesNotExceedMaxDepth
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        max_allowed_depth = context.query.max_depth
        return if max_allowed_depth.nil?

        visitor = context.visitor

        # operation or fragment name
        current_field_scope = nil
        current_depth = 0
        skip_current_scope = false

        # {name => depth} pairs for operations and fragments
        depths = Hash.new { |h, k| h[k] = 0 }

        # {name => [fragmentName...]} pairs
        fragments = Hash.new { |h, k| h[k] = []}

        visitor[GraphQL::Language::Nodes::Document].leave << -> (node, parent) {
          context.errors.none? && assert_under_max_depth(context, max_allowed_depth, depths, fragments)
        }

        visitor[GraphQL::Language::Nodes::OperationDefinition] << -> (node, parent) {
          current_field_scope = node.name
        }

        visitor[GraphQL::Language::Nodes::FragmentDefinition] << -> (node, parent) {
          current_field_scope = node.name
        }

        visitor[GraphQL::Language::Nodes::Field] << -> (node, parent) {
          # Don't validate queries on __schema, __type
          skip_current_scope ||= context.skip_field?(node.name)

          if node.selections.any? && !skip_current_scope
            current_depth += 1
            if current_depth > depths[current_field_scope]
              depths[current_field_scope] = current_depth
            end
          end
        }

        visitor[GraphQL::Language::Nodes::Field].leave << -> (node, parent) {
          if skip_current_scope && context.skip_field?(node.name)
            skip_current_scope = false
          elsif node.selections.any?
            current_depth -= 1
          end
        }

        visitor [GraphQL::Language::Nodes::FragmentSpread] << -> (node, parent) {
          fragments[current_field_scope] << node.name
        }
      end

      private

      def assert_under_max_depth(context, max_allowed_depth, depths, fragments)
        context.operations.each do |op_name, operation|
          op_depth = get_total_depth(op_name, depths, fragments)
          if op_depth > max_allowed_depth
            op_name ||= "operation"
            context.errors << message("#{op_name} has depth of #{op_depth}, which exceeds max depth of #{max_allowed_depth}", operation)
          end
        end
      end

      # Get the total depth of a given fragment or operation
      def get_total_depth(scope_name, depths, fragments)
        own_fragments = fragments[scope_name]
        depths[scope_name] + own_fragments.reduce(0) { |memo, frag_name| memo + get_total_depth(frag_name, depths, fragments) }
      end
    end
  end
end
