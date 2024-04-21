module GraphQL
  module Bulk
    module Visitors
      class ConnectionNodeExtractionVisitor < GraphQL::Language::Visitor
        def initialize(document, connection_node)
          super(document)
          @connection_node = connection_node
        end

        def on_field(node, parent)
          # Stop traversing once we find the node. No need to go any further
          return if node == @connection_node.node

          # Keep this node if it's in the path
          return super if @connection_node.path.include?(node)

          # Destroy all other nodes
          super(DELETE_NODE, parent)
        end
      end
    end
  end
end
