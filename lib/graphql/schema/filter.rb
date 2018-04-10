# frozen_string_literal: true

module GraphQL
  class Schema
    class Filter
      def initialize(field:)
        @field = field
      end

      def resolve_field(obj, args, ctx)
        yield(obj, args, ctx)
      end
    end

    class ConnectionFilter < Filter
      def initialize(field:)
        # TODO: this could be a bit weird, because these fields won't be present
        # after initialization, only in the `to_graphql` response.
        # This calculation _could_ be moved up if need be.
        field.argument :after, "String", "Returns the elements in the list that come after the specified global ID.", required: false
        field.argument :before, "String", "Returns the elements in the list that come before the specified global ID.", required: false
        field.argument :first, "Int", "Returns the first _n_ elements from the list.", required: false
        field.argument :last, "Int", "Returns the last _n_ elements from the list.", required: false
        super
      end

      def resolve_field(obj, args)
        inner_args = args.dup
        inner_args.delete(:first)
        inner_args.delete(:after)
        inner_args.delete(:last)
        inner_args.delete(:before)
        nodes = yield(obj, inner_args)
        if nodes.nil?
          nil
        elsif nodes.is_a?(GraphQL::Execution::Execute::Skip)
          nodes
        elsif nodes.is_a? GraphQL::ExecutionError
          raise nodes
        elsif nodes.is_a? GraphQL::Relay::BaseConnection
          # TODO can we avoid double-wrapping?
          nodes
        else
          parent = obj.object
          connection_class = GraphQL::Relay::BaseConnection.connection_for_nodes(nodes)
          connection_class.new(nodes, args, field: @field.graphql_definition, max_page_size: @field.max_page_size, parent: parent, context: obj.context)
        end
      end
    end
  end
end
