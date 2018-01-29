# frozen_string_literal: true
module GraphQL
  module InternalRepresentation
    class Node
      # @api private
      DEFAULT_TYPED_CHILDREN = Proc.new { |h, k| h[k] = {} }
      NO_TYPED_CHILDREN = {}
      def NO_TYPED_CHILDREN.dup
        NO_TYPED_CHILDREN
      end

      def NO_TYPED_CHILDREN.any?
        false
      end

      NO_TYPED_CHILDREN.freeze

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
        @typed_children ||= begin
          if @scoped_children.any?
            new_tc = Hash.new(&DEFAULT_TYPED_CHILDREN)
            all_object_types = Set.new
            scoped_children.each_key { |t| all_object_types.merge(@query.possible_types(t)) }
            # Remove any scoped children which don't follow this return type
            # (This can happen with fragment merging where lexical scope is lost)
            all_object_types &= @query.possible_types(@return_type.unwrap)
            all_object_types.each do |t|
              new_tc[t] = get_typed_children(t)
            end
            new_tc
          else
            NO_TYPED_CHILDREN
          end
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

      # @return [GraphQL::BaseType] The expected wrapped type this node must return.
      attr_reader :return_type

      # @return [InternalRepresentation::Node, nil]
      attr_reader :parent

      def initialize(
          name:, owner_type:, query:, return_type:, parent:,
          ast_nodes: [],
          definition_name: []
        )
        @name = name
        @query = query
        @owner_type = owner_type
        @parent = parent
        @typed_children = nil
        @scoped_children = Hash.new(&DEFAULT_TYPED_CHILDREN)
        @definition_name = definition_name
        @return_type = return_type
        @ast_nodes = ast_nodes
      end

      def initialize_copy(other_node)
        super
        # Bust some caches:
        @typed_children = nil
        @definition = nil
        # Shallow-copy some state:
        @scoped_children = other_node.scoped_children.dup
        @ast_nodes = ast_nodes.dup
      end

      def ==(other)
        other.is_a?(self.class) &&
          other.name == name &&
          other.parent == parent &&
          other.return_type == return_type &&
          other.owner_type == owner_type &&
          other.scoped_children == scoped_children
      end

      def arguments
        @query.arguments_for(self, definition)
      end

      def definition
        @definition ||= begin
          @definition_name && @query.get_field(@owner_type, @definition_name)
        end
      end

      def ast_node
        @ast_nodes.first
      end
      attr_reader :definition_name

      def inspect
        all_children_names = scoped_children.values.map(&:keys).flatten.uniq.join(", ")
        all_locations = ast_nodes.map {|n| "#{n.line}:#{n.col}" }.join(", ")
        "#<Node #{@owner_type}.#{@name} -> #{@return_type} {#{all_children_names}} @ [#{all_locations}] #{object_id}>"
      end

      # Merge selections from `new_parent` into `self`.
      # Selections are merged in place, not copied.
      def deep_merge_node(new_parent, scope: nil, merge_self: true)
        if merge_self
          @ast_nodes |= new_parent.ast_nodes
        end
        if new_parent.scoped_children.any?
          scope ||= Scope.new(@query, @return_type.unwrap)
          new_parent.scoped_children.each do |obj_type, new_fields|
            inner_scope = scope.enter(obj_type)
            inner_scope.each do |scoped_type|
              prev_fields = @scoped_children[scoped_type]
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
        end
      end

      # @return [GraphQL::Query]
      attr_reader :query

      def subscription_topic
        @subscription_topic ||= begin
          scope = if definition.subscription_scope
            @query.context[definition.subscription_scope]
          else
            nil
          end
          Subscriptions::Event.serialize(
            definition_name,
            @query.arguments_for(self, definition),
            definition,
            scope: scope
          )
        end
      end

      protected

      attr_writer :owner_type, :parent

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
