require "set"

module GraphQL
  module InternalRepresentation
    class Node
      def initialize(ast_node:, return_type:, on_types: Set.new, name: nil, field: nil, children: {}, spreads: [], directives: [])
        @ast_node = ast_node
        @return_type = return_type
        @on_types = on_types
        @name = name
        @field = field
        @children = children
        @spreads = spreads
        @directives = directives
      end

      # Note: by the time this gets out of the Rewrite phase, this will be empty -- it's emptied out when fragments are merged back in
      # @return [Array<GraphQL::Language::Nodes::FragmentSpreads>] Fragment names that were spread in this node
      attr_reader :spreads

      # These are the compiled directives from fragment spreads, inline fragments, and the field itself
      # @return [Array<GraphQL::Language::Nodes::Directive>]
      attr_reader :directives

      # @return [GraphQL::Field] The definition to use to execute this node
      attr_reader :field

      # @return [String] the name to use for the result in the response hash
      attr_reader :name

      # @return [GraphQL::Language::Nodes::AbstractNode] The AST node (or one of the nodes) where this was derived from
      attr_reader :ast_node

      # This may come from the previous field's return value or an explicitly-typed fragment
      # @example On-type from previous return value
      # {
      #   person(id: 1) {
      #     firstName # => on_type is person
      #   }
      # }
      # @example On-type from explicit type condition
      # {
      #   node(id: $nodeId) {
      #     ... on Nameable {
      #       firstName # => on_type is Nameable
      #     }
      #   }
      # }
      # @return [Set<GraphQL::ObjectType, GraphQL::InterfaceType>] the types this field applies to
      attr_reader :on_types

      # @return [GraphQL::BaseType]
      attr_reader :return_type

      # @return [Array<GraphQL::Query::Node>]
      attr_reader :children

      def inspect(indent = 0)
        own_indent = " " * indent
        self_inspect = "#{own_indent}<Node #{name} (#{field ? field.name + ": " : ""}{#{on_types.to_a.join("|")}} -> #{return_type})>"
        if children.any?
          self_inspect << " {\n#{children.values.map { |n| n.inspect(indent + 2 )}.join("\n")}\n#{own_indent}}"
        end
        self_inspect
      end
    end
  end
end
