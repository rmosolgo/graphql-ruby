# frozen_string_literal: true
# typed: true
module GraphQL
  module StaticValidation
    #--
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor
    module MaxIntrospectionDepth
      MAX_LIST_DEPTH = 3

      def on_field(node, parent)
        if (node.name == "__schema" || node.name == "__type") && introspection_depth_exceeded?(node, 0, {})
          add_error(GraphQL::StaticValidation::MaxIntrospectionDepthError.new(
            "Maximum introspection depth exceeded",
            nodes: node,
          ))
        end
        super
      end

      private

      def introspection_depth_exceeded?(node, depth, visited_fragments)
        case node
        when GraphQL::Language::Nodes::FragmentSpread
          fragment = context.fragments[node.name]
          return false if !fragment

          # Revisit only at greater depth, avoiding cycles and exponential fragment expansion.
          visited_depth = visited_fragments[node.name]
          return false if visited_depth && visited_depth >= depth
          visited_fragments[node.name] = depth
          node = fragment
        when GraphQL::Language::Nodes::Field
          case node.name
          when "fields", "interfaces", "possibleTypes", "inputFields"
            depth += 1
            return true if depth >= MAX_LIST_DEPTH
          end
        end

        node.selections.any? { |selection| introspection_depth_exceeded?(selection, depth, visited_fragments) }
      end
    end
  end
end
