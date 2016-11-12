module GraphQL
  module InternalRepresentation
    # A selection is a single field on an object.
    # It's "backed" by one or more {Node}s.
    class Selection
      # @return [GraphQL::BaseType] The type this selection belongs to
      attr_reader :type

      def initialize(type:)
        @type = type
        @selections = Hash.new { |h, k| h[k] = Subselection.new }
      end

      def add_selection(name, irep_node)
        @selections[name].add_node(irep_node)
      end

      def each_selection
        @selections.each do |name, subselection|
          if !subselection.skipped?
            yield(name, subselection.nodes)
          end
        end
      end

      class Subselection
        attr_reader :nodes

        def initialize
          @nodes = []
          @skipped = false
        end

        def add_node(node)
          @nodes << node
          @skipped ||= node.skipped?
        end

        def skipped?
          @skipped
        end
      end
    end
  end
end
