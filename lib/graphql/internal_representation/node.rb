# frozen_string_literal: true
require "set"

module GraphQL
  module InternalRepresentation
    class Node
      def initialize(parent:, ast_node: nil, return_type: nil, owner_type: nil, name: nil, definition_name: nil, definition: nil, spreads: [], directives: Set.new, included: true, typed_children: Hash.new {|h, k| h[k] = {} }, definitions: {}, children: {})
        @ast_node = ast_node
        @return_type = return_type
        @owner_type = owner_type
        @name = name
        @definition_name = definition_name
        @definition = definition
        @parent = parent
        @spreads = spreads
        @directives = directives
        @included = included
        @typed_children = typed_children
        @children = children
        @definitions = definitions
      end

      # @return [Hash{GraphQL::BaseType => Hash{String => Node}] Children for each type condition
      attr_reader :typed_children

      # Note: by the time this gets out of the Rewrite phase, this will be empty -- it's emptied out when fragments are merged back in
      # @return [Array<GraphQL::InternalRepresentation::Node>] Fragment names that were spread in this node
      attr_reader :spreads

      # These are the compiled directives from fragment spreads, inline fragments, and the field itself
      # @return [Set<GraphQL::Language::Nodes::Directive>]
      attr_reader :directives

      # @return [String] the name for this node's definition ({#name} may be a field's alias, this is always the name)
      attr_reader :definition_name

      # A _shallow_ cache of type-field pairs for executing & analyzing this node.
      #
      # Known to be buggy: some fields are deeply merged when they shouldn't be.
      #
      # @example On-type from previous return value
      # {
      #   person(id: 1) {
      #     firstName # => defined type is person
      #   }
      # }
      # @example On-type from explicit type condition
      # {
      #   node(id: $nodeId) {
      #     ... on Nameable {
      #       firstName # => defined type is Nameable
      #     }
      #   }
      # }
      # @deprecated use {#typed_children} to find matching children, the use the node's {#definition}
      # @return [Hash<GraphQL::BaseType => GraphQL::Field>] definitions to use for each possible type
      attr_reader :definitions

      # @return [GraphQL::Field, GraphQL::Directive] the static definition for this field (it might be an interface field definition even though an object field definition will be used at runtime)
      attr_reader :definition

      # @return [String] the name to use for the result in the response hash
      attr_reader :name

      # @return [GraphQL::Language::Nodes::AbstractNode] The AST node (or one of the nodes) where this was derived from
      attr_reader :ast_node

      # @return [GraphQL::BaseType]
      attr_reader :return_type

      # @return [GraphQL::BaseType]
      attr_reader :owner_type

      # Returns leaf selections on this node.
      # Known to be buggy: deeply nested selections are not handled properly
      # @deprecated use {#typed_children} instead
      # @return [Array<Node>]
      attr_reader :children

      # @return [Boolean] false if every field for this node included `@skip(if: true)`
      attr_accessor :included
      alias :included? :included

      def skipped?
        !@included
      end

      # @return [GraphQL::InternalRepresentation::Node] The node which this node is a child of
      attr_reader :parent

      # @return [GraphQL::InternalRepresentation::Node] The root node which this node is a (perhaps-distant) child of, or `self` if this is a root node
      def owner
        @owner ||= begin
          if parent.nil?
            self
          else
            parent.owner
          end
        end
      end

      def path
        warn("InternalRepresentation::Node#path is deprecated, use Query::Context#path instead")
        if parent
          path = parent.path
          path << name
          path << @index if @index
          path
        else
          []
        end
      end

      attr_writer :index

      def inspect(indent = 0)
        own_indent = " " * indent
        self_inspect = "#{own_indent}<Node #{name} #{skipped? ? "(skipped)" : ""}(#{definition_name} -> #{return_type})>"
        if typed_children.any?
          self_inspect << " {"
          typed_children.each do |type_defn, children|
            self_inspect << "\n#{own_indent}  #{type_defn} => (#{children.keys.join(",")})"
          end
          self_inspect << "\n#{own_indent}}"
        end
        self_inspect
      end
    end
  end
end
