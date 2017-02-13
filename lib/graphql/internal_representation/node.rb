module GraphQL
  module InternalRepresentation
    class Node
      # @return [String] the name this node has in the response
      attr_reader :name

      # @return [GraphQL::ObjectType]
      attr_reader :owner_type

      # @return [Hash<GraphQL::ObjectType, Hash<String => Node>>] selections on this node for each type
      attr_reader :typed_children

      # @return [Set<Language::Nodes::AbstractNode>] AST nodes which are represented by this node
      def ast_nodes
        @ast_nodes ||= Set.new
      end

      # @return [Set<GraphQL::Field>] Field definitions for this node (there should only be one!)
      def definitions
        @definitions ||= Set.new
      end

      # @return [GraphQL::BaseType]
      attr_reader :return_type

      def initialize(
          name:, owner_type:, query:, return_type:,
          ast_nodes: [],
          definitions: nil, typed_children: nil
        )
        @name = name
        @query = query
        @owner_type = owner_type
        @typed_children = typed_children || Hash.new { |h1, k1| h1[k1] = {} }
        @ast_nodes = ast_nodes
        @definitions = definitions
        @return_type = return_type
      end

      def definition_name
        @definition_name ||= definition.name
      end

      def definition
        @definition ||= definitions.first
      end

      def ast_node
        @ast_node ||= ast_nodes.first
      end

      def inspect
        "#<Node #{@owner_type}.#{@name} -> #{@return_type}>"
      end
    end
  end
end
