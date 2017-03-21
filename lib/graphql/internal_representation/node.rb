# frozen_string_literal: true
module GraphQL
  module InternalRepresentation
    class Node
      # @return [String] the name this node has in the response
      attr_reader :name

      # @return [GraphQL::ObjectType]
      attr_reader :owner_type

      # @return [Hash<GraphQL::ObjectType, Hash<String => Node>>] selections on this node for each type
      def typed_children
        @typed_childen ||= begin
          new_tc = Hash.new { |h, k| h[k] = {} }
          if @scoped_children.any?
            all_object_types = Set.new
            scoped_children.each_key { |t| all_object_types.merge(@query.possible_types_set(t)) }
            all_object_types.each do |t|
              new_tc[t] = get_typed_children(t)
            end
          end
          new_tc
        end
      end

      # @return [Hash<GraphQL::BaseType, Hash<String => Node>>] selections on this node for each type
      attr_reader :scoped_children

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

      # @return [InternalRepresentation::Node, nil]
      attr_reader :parent

      def initialize(
          name:, owner_type:, query:, return_type:, parent:,
          ast_nodes: nil,
          definitions: nil
        )
        @name = name
        @query = query
        @owner_type = owner_type
        @parent = parent
        @typed_children = nil
        @scoped_children = Hash.new { |h1, k1| h1[k1] = {} }
        @ast_nodes = ast_nodes
        @definitions = definitions
        @return_type = return_type
      end

      def initialize_copy(other_node)
        super
        @scoped_children = other_node.scoped_children.dup
        @typed_children = nil
        @definition = nil
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
      def deep_merge_node(new_parent)
        new_parent.scoped_children.each do |obj_type, new_fields|
          prev_fields = @scoped_children[obj_type]
          new_fields.each do |name, new_node|
            prev_node = prev_fields[name]
            if prev_node
              prev_node.ast_nodes.merge(new_node.ast_nodes)
              prev_node.definitions.merge(new_node.definitions)
              prev_node.deep_merge_node(new_node)
            else
              prev_fields[name] = new_node.dup
            end
          end
        end
      end

      protected

      attr_writer :owner_type, :parent

      private

      def get_typed_children(obj_type)
        new_tc = {}
        @scoped_children.each do |scope_type, scope_nodes|
          if GraphQL::Execution::Typecast.subtype?(scope_type, obj_type)
            scope_nodes.each do |name, new_node|
              prev_node = new_tc[name]
              if prev_node
                prev_node.ast_nodes.merge(new_node.ast_nodes)
                prev_node.definitions.merge(new_node.definitions)
                prev_node.deep_merge_node(new_node)
              else
                copied_node = new_node.dup
                copied_node.owner_type = obj_type
                copied_node.parent = self
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
