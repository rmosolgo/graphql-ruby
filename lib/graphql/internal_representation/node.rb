# frozen_string_literal: true
module GraphQL
  module InternalRepresentation
    class Node
      # @return [String] the name this node has in the response
      attr_reader :name

      # @return [GraphQL::ObjectType]
      attr_reader :owner_type

      # Each key is a {GraphQL::ObjectType} which this selection _may_ be made on.
      # The values for that key are selections which apply to that type.
      #
      # This value is derived from {#scoped_children} after the rewrite is finished.
      # @return [Hash<GraphQL::ObjectType, Hash<String => Node>>]
      def typed_children
        @typed_childen ||= begin
          new_tc = Hash.new { |h, k| h[k] = {} }
          if @scoped_children.any?
            all_object_types = Set.new
            scoped_children.each_key { |t| all_object_types.merge(@query.possible_types(t)) }
            all_object_types.each do |t|
              new_tc[t] = get_typed_children(t)
            end
          end
          new_tc
        end
      end

      # These children correspond closely to scopes in the AST.
      # Keys _may_ be abstract types. They're assumed to be read-only after rewrite is finished
      # because {#typed_children} is derived from them.
      #
      # Using {#scoped_children} during the rewrite step reduces the overhead of reifying
      # abstract types because they're only reified _after_ the rewrite.
      # @return [Hash<GraphQL::BaseType, Hash<String => Node>>]
      attr_reader :scoped_children

      # @return [Array<Language::Nodes::AbstractNode>] AST nodes which are represented by this node
      attr_reader :ast_nodes

      # @return [Array<GraphQL::Field>] Field definitions for this node (there should only be one!)
      attr_reader :definitions

      # @return [GraphQL::BaseType]
      attr_reader :return_type

      def initialize(
          name:, owner_type:, query:, return_type:,
          ast_nodes: [],
          definitions: []
        )
        @name = name
        @query = query
        @owner_type = owner_type
        @typed_children = nil
        @scoped_children = Hash.new { |h1, k1| h1[k1] = {} }
        @ast_nodes = ast_nodes
        @definitions = definitions
        @return_type = return_type
      end

      def initialize_copy(other_node)
        super
        # Bust some caches:
        @typed_children = nil
        @definition = nil
        @definition_name = nil
        @ast_node = nil
        # Shallow-copy some state:
        @scoped_children = other_node.scoped_children.dup
        @ast_nodes = other_node.ast_nodes.dup
        @definitions = other_node.definitions.dup
      end

      def definition_name
        @definition_name ||= definition.name
      end

      def definition
        @definition ||= @query.get_field(@owner_type, @definitions.first.name)
      end

      def ast_node
        @ast_node ||= ast_nodes.first
      end

      def inspect
        "#<Node #{@owner_type}.#{@name} -> #{@return_type}>"
      end

      # Merge selections from `new_parent` into `self`.
      # Selections are merged in place, not copied.
      def deep_merge_node(new_parent, merge_self: true)
        if merge_self
          @ast_nodes.concat(new_parent.ast_nodes)
          @definitions.concat(new_parent.definitions)
        end
        new_parent.scoped_children.each do |obj_type, new_fields|
          prev_fields = @scoped_children[obj_type]
          new_fields.each do |name, new_node|
            prev_node = prev_fields[name]
            if prev_node
              prev_node.deep_merge_node(new_node)
            else
              prev_fields[name] = new_node
            end
          end
        end
      end

      protected

      attr_writer :owner_type

      private

      # Get applicable children from {#scoped_children}
      # @param obj_type [GraphQL::ObjectType]
      # @return [Hash<String => Node>]
      def get_typed_children(obj_type)
        new_tc = {}
        @scoped_children.each do |scope_type, scope_nodes|
          if GraphQL::Execution::Typecast.subtype?(scope_type, obj_type)
            scope_nodes.each do |name, new_node|
              prev_node = new_tc[name]
              if prev_node
                prev_node.deep_merge_node(new_node)
              elsif scope_type == obj_type && new_node.scoped_children.none?
                new_tc[name] = new_node
              else
                copied_node = new_node.dup
                copied_node.owner_type = obj_type
                new_tc[name] = copied_node
              end
            end
          end
        end
        new_tc
      end
    end
  end
end
