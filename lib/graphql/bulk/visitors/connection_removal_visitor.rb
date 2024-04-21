module GraphQL
  module Bulk
    module Visitors
      class ConnectionRemovalVisitor < GraphQL::Language::Visitor
        Connection = Struct.new(:node, :path)

        attr_reader :connections

        GraphQL::Language::Nodes::AbstractNode.descendants.each do |descendant|
          underscored_name = descendant.name.split("::").last.
                             gsub(/([a-z])([A-Z])/, '\1_\2'). # insert underscores
                             downcase
          node_method = "on_#{underscored_name}"

          class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
            # Here's an example of what the dynamically-defined method might look like:
            #
            #   def on_some_node(node, parent)
            #     @path.push(node.dup)
            #
            #     result = super
            #
            #     @path.pop
            #
            #     result
            #   end
            #
            # The default implementation for visiting an AST node.
            # It doesn't _do_ anything, but it continues to visiting the node's children.
            # To customize this hook, override one of its make_visit_methods (or the base method?)
            # in your subclasses.
            #
            # For compatibility, it calls hook procs, too.
            # @param node [GraphQL::Language::Nodes::AbstractNode] the node being visited
            # @param parent [GraphQL::Language::Nodes::AbstractNode, nil] the previously-visited node, or `nil` if this is the root node.
            # @return [Array, nil] If there were modifications, it returns an array of new nodes, otherwise, it returns `nil`.
            def #{node_method}(node, parent)
              @path.push(node.dup)

              result = super

              @path.pop

              result
            end
          RUBY
        end

        def initialize(document, depth: 1)
          super(document)
          @depth = depth
        end

        def visit
          @path = []
          @connections = []
          @connection_depth = 0
          super
        end

        def on_field(node, parent)
          result = nil

          if connection?(node)
            @connection_depth += 1
            if @connection_depth >= @depth
              @connections.push(Connection.new(node, @path.dup))
              result = super(DELETE_NODE, parent)
            end
          end

          @path.push(node.dup)

          result = super if result.nil?

          @path.pop

          result
        end

        def connection?(node)
          return false if node.children.blank?

          selections = node.selections
          selections.first.name.in?(["nodes", "edges"])
        end
      end
    end
  end
end
