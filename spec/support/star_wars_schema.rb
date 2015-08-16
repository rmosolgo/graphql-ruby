# Taken from graphql-relay-js
# https://github.com/graphql/graphql-relay-js/blob/master/src/__tests__/starWarsSchema.js

class NodeImplementation
  def object_from_id(id)
    type_name, id = GraphQL::Relay::Node.from_global_id(id)
    STAR_WARS_DATA[type_name][id]
  end

  def type_from_object(object)
    STAR_WARS_DATA["Faction"].values.include?(object) ? Faction : Ship
  end
end

NodeInterface, NodeField = GraphQL::Relay::Node.create(NodeImplementation.new)

Faction = GraphQL::ObjectType.define do
  name "Faction"
  interfaces [NodeInterface]
  field :id, field: GraphQL::Relay::GlobalIdField.new("Faction")
  field :name, types.String
  connection :ships, -> { ShipConnection } do
    resolve -> (obj, args, ctx) {
      obj.ships.map {|ship_id| STAR_WARS_DATA["Ship"][ship_id] }
    }
  end
end

Ship = GraphQL::ObjectType.define do
  name "Ship"
  interfaces [NodeInterface]
  field :id, field: GraphQL::Relay::GlobalIdField.new("Ship")
  field :name, types.String
end

ShipConnection = GraphQL::Relay::ArrayConnection.create_type(Ship)

QueryType = GraphQL::ObjectType.define do
  name "Query"
  field :rebels, Faction do
    resolve -> (obj, args, ctx) { STAR_WARS_DATA["Faction"]["1"]}
  end

  field :empire, Faction do
    resolve -> (obj, args, ctx) { STAR_WARS_DATA["Faction"]["2"]}
  end

  field :node, field: NodeField
end


#
# IntroduceShipInput = GraphQL::InputObjectType.define do
#   input_field :clientMutationId, !types.String
#   input_field :shipName, !types.String
#   input_field :factionId, !types.ID
# end
#
# IntroduceShipPayload = GraphQL::ObjectType.define do
#   field :clientMutationId, !types.String
#   field :ship, Ship
#   field :faction, Faction
# end
#

IntroduceShipMutation = GraphQL::Relay::Mutation.define do
  # Used as the root for derived types:
  name "IntroduceShip"

  # Nested under `input` in the query:
  input_field :shipName, !types.String
  input_field :factionId, !types.ID

  # Result may have access to these fields:
  return_field :ship, Ship
  return_field :faction, Faction

  # Here's the mutation operation:
  resolve -> (inputs) {
    faction_id = inputs["factionId"]
    ship = STAR_WARS_DATA.create_ship(inputs["shipName"], faction_id)
    faction = STAR_WARS_DATA["Faction"][faction_id]
    { ship: ship, faction: faction }
  }
end

MutationType = GraphQL::ObjectType.define do
  name "Mutation"
  # The mutation object exposes a field:
  field :introduceShip, field: IntroduceShipMutation.field
end


StarWarsSchema = GraphQL::Schema.new(query: QueryType, mutation: MutationType)
