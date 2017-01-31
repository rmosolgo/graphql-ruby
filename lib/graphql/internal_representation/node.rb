module GraphQL
  module InternalRepresentation
    class Node
      # @return [String] the name this node has in the response
      attr_reader :name

      # @return [GraphQL::ObjectType]
      attr_reader :owner_type

      # @return [Hash<GraphQL::ObjectType, Hash<String, ReNode>>] selections on this node for each type
      attr_reader :typed_children

      # @return [Set<Language::Nodes::AbstractNode>] AST nodes which are represented by this node
      attr_reader :ast_nodes

      # @return [Set<Language::Nodes::AbstractNode>]
      attr_reader :ast_spreads

      # @return [Set<GraphQL::Field>] Field definitions for this node (there should only be one!)
      attr_reader :definitions

      # @return [GraphQL::BaseType]
      def return_type
        @return_type ||= definitions.first.type.unwrap
      end

      # TODO This should be part of the directive,
      # not hardcoded here
      def skipped?
        @skipped ||= begin
          nodes_skipped = @ast_nodes.all? { |n| !GraphQL::Execution::DirectiveChecks.include?(n.directives, @query) }
          res = nodes_skipped || (@ast_spreads.any? && @ast_spreads.all? { |n| !GraphQL::Execution::DirectiveChecks.include?(n.directives, @query) } )
          res
        end
      end

      # @return [Set<GraphQL::Language::Nodes::Directive>]
      attr_reader :ast_directives

      def initialize(
          name:, owner_type:, query:,
          ast_nodes: [], ast_directives: Set.new, ast_spreads: Set.new,
          definitions: Set.new, typed_children: nil
        )
        @name = name
        @query = query
        @owner_type = owner_type
        @typed_children = typed_children || Hash.new { |h1, k1| h1[k1] = {} }
        @ast_nodes = ast_nodes
        @ast_directives = ast_directives
        @ast_spreads = ast_spreads
        @definitions = definitions
      end

      # TODO: test deep merging frag into frag
      def deep_copy
        new_typed_children = Hash.new { |h1, k1| h1[k1] = {} }
        @typed_children.each do |obj_type, fields|
          fields.each do |name, node|
            new_typed_children[obj_type][name] = node.deep_copy
          end
        end
        self.class.new(
          name: @name,
          owner_type: @owner_type,
          query: @query,
          ast_nodes: @ast_nodes.dup,
          ast_spreads: @ast_spreads.dup,
          definitions: @definitions.dup,
          typed_children: new_typed_children,
        )
      end

      def definition_name
        @definition_name ||= definition.name
      end

      def definition
        @definition ||= @definitions.first
      end

      def ast_node
        @ast_node ||= @ast_nodes.first
      end

      def inspect
        "#<Node #{@owner_type}.#{@name} -> #{@return_type}>"
      end
    end
  end
end
