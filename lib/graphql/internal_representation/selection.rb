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
        @typed_child_nodes = Selections.build(query, nodes)
        @typed_subselections = Hash.new { |h, k| h[k] = {} }
      end

      attr_reader :definition_name, :name, :irep_node

      def skipped?
        @skipped
      end

      def each_selection(type:)
        subselections = @typed_subselections[type]
        @typed_child_nodes[type].each do |name, child_nodes|
          subselection = subselections[name] ||= self.class.new(query: @query, nodes: child_nodes)
          if !subselection.skipped?
            yield(name, subselection)
          end
        end
      end
    end
  end
end
