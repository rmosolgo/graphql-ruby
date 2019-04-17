# frozen_string_literal: true
module NonNullableDummy
  class NonNullableNode < GraphQL::Schema::Object; end

  class NonNullableNodeEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(NonNullableNode, null: false)
  end

  class NonNullableNodeEdgeConnectionType < GraphQL::Types::Relay::BaseConnection
    edge_type(NonNullableNodeEdgeType, nodes_field: false)
  end

  class Query < GraphQL::Schema::Object
    field :connection, NonNullableNodeEdgeConnectionType, null: false
  end

  class Schema < GraphQL::Schema
    query Query
  end
end
