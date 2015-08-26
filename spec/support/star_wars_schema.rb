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



Ship = GraphQL::ObjectType.define do
  name "Ship"
  interfaces [NodeInterface]
  field :id, field: GraphQL::Relay::GlobalIdField.new("Ship")
  field :name, types.String
end

BaseType = GraphQL::ObjectType.define do
  name "Base"
  interfaces [NodeInterface]
  global_id_field :id
  field :name, types.String
  field :planet, types.String
end

Faction = GraphQL::ObjectType.define do
  name "Faction"
  interfaces [NodeInterface]
  field :id, field: GraphQL::Relay::GlobalIdField.new("Faction")
  field :name, types.String
  connection :ships, Ship.connection_type do
    # Resolve field should return an Array, the Connection
    # will do the rest!
    resolve -> (obj, args, ctx) {
      all_ships = obj.ships.map {|ship_id| STAR_WARS_DATA["Ship"][ship_id] }
      if args[:nameIncludes]
        all_ships = all_ships.select { |ship| ship.name.include?(args[:nameIncludes])}
      end
      all_ships
    }
    # You can define arguments here and use them in the connection
    argument :nameIncludes, types.String
  end
  connection :bases, BaseType.connection_type do
    # Resolve field should return an Array, the Connection
    # will do the rest!
    resolve -> (obj, args, ctx) {
      Base.where(id: obj.bases)
    }
  end
end

# Define a mutation. It will also:
#   - define a derived InputObjectType
#   - define a derived ObjectType (for return)
#   - define a field, accessible from {Mutation#field}
#
# The resolve proc takes `inputs, ctx`, where:
#   - `inputs` has the keys defined with `input_field`
#   - `ctx` is the Query context (like normal fields)
#
# Notice that you leave out clientMutationId.
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
  resolve -> (inputs, ctx) {
    faction_id = inputs["factionId"]
    ship = STAR_WARS_DATA.create_ship(inputs["shipName"], faction_id)
    faction = STAR_WARS_DATA["Faction"][faction_id]
    { ship: ship, faction: faction }
  }
end

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

MutationType = GraphQL::ObjectType.define do
  name "Mutation"
  # The mutation object exposes a field:
  field :introduceShip, field: IntroduceShipMutation.field
end

StarWarsSchema = GraphQL::Schema.new(query: QueryType, mutation: MutationType)
