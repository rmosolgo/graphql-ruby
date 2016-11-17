module GraphQL
  module InternalRepresentation
    # A selection is a single field on an object.
    # It's "backed" by one or more {Node}s.
    class Selection
      def initialize(query:, nodes:)
        @irep_node = nodes.first
        @definition_name = @irep_node.definition_name
        @name = @irep_node.name

        @skipped = nodes.any?(&:skipped?)
        @query = query
        @typed_child_nodes = build_typed_selections(query, nodes)
        @typed_subselections = Hash.new { |h, k| h[k] = {} }
      end

      # @return [String] name of the field in this selection
      attr_reader :definition_name

      # @return [String] the key of this selection in the result (may be the field's alias)
      attr_reader :name

      # @return [Node] A "representative" node for this selection. Legacy. In the case that a selection appears in multiple nodes, is this valuable?
      attr_reader :irep_node

      # @return [Boolean] true if _any_ of the backing nodes are skipped
      def skipped?
        @skipped
      end

      # Call the block with each name & subselection whose conditions match `type`
      # @param type [GraphQL::BaseType] The type to get selections on
      # @yieldparam name [String] the key in the child selection
      # @yieldparam subselection [Selection] the selection for that key
      def each_selection(type:)
        subselections = @typed_subselections[type]
        @typed_child_nodes[type].each do |name, child_nodes|
          subselection = subselections[name] ||= self.class.new(query: @query, nodes: child_nodes)
          if !subselection.skipped?
            yield(name, subselection)
          end
        end
      end

      private

      # Turn `nodes` into a two-dimensional hash, based on type information from `query`
      # @return [Hash] A 2d mapping of `{ type => { name => nodes } }`
      def build_typed_selections(query, nodes)
        selections = Hash.new { |h,k| h[k] = Hash.new { |h2, k2| h2[k2] = [] } }

        object_types = Set.new

        warden = query.warden
        ctx = query.context

        # Find the object types which are possible among typed children
        nodes.each do |node|
          node.typed_children.each_key do |type_cond|
            object_types.merge(warden.possible_types(type_cond))
          end
        end

        # For each object types, find the irep_nodes
        # which may apply to it, then add the children
        # of that node to this object's children
        nodes.each do |node|
          node.typed_children.each do |type_cond, children|
            object_types.each do |obj_type|
              obj_selections = selections[obj_type]
              if GraphQL::Execution::Typecast.compatible?(obj_type, type_cond, ctx)
                children.each do |name, irep_node|
                  obj_selections[name] << irep_node
                end
              end
            end
          end
        end

        selections
      end
    end
  end
end
