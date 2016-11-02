require "set"

module GraphQL
  module InternalRepresentation
    class Node
      def initialize(parent:, ast_node: nil, return_type: nil, name: nil, definition_name: nil, definitions: {}, spreads: [], directives: Set.new, included: true, typed_children: Hash.new {|h, k| h[k] = {} })
        @ast_node = ast_node
        @return_type = return_type
        @name = name
        @definition_name = definition_name
        @parent = parent
        @definitions = definitions
        @spreads = spreads
        @directives = directives
        @included = included
        @typed_children = typed_children
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

      # A cache of type-field pairs for executing & analyzing this node
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
      # @return [Hash<GraphQL::BaseType => GraphQL::Field>] definitions to use for each possible type
      attr_reader :definitions

      # @return [String] the name to use for the result in the response hash
      attr_reader :name

      # @return [GraphQL::Language::Nodes::AbstractNode] The AST node (or one of the nodes) where this was derived from
      attr_reader :ast_node

      # @return [GraphQL::BaseType]
      attr_reader :return_type

      # @deprecated Use {#typed_children} instead
      # @return [Hash{String => Node}]
      def children
        if typed_children.size > 1
          raise("This node has children of different types, use #typed_children")
        else
          typed_children.values.first || {}
        end
      end

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
        self_inspect = "#{own_indent}<Node #{name} #{skipped? ? "(skipped)" : ""}(#{definition_name}: {#{definitions.keys.join("|")}} -> #{return_type})>"
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
