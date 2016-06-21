# Adapted from graphql-relay-js
# https://github.com/graphql/graphql-relay-js/blob/master/src/__tests__/starWarsSchema.js

# This object exposes helpers for working with global IDs:
# - global id creation & "decrypting"
# - a find-object-by-global ID field
# - an interface for Relay ObjectTypes to implement
# See global_node_identification.rb for the full API.
NodeIdentification = GraphQL::Relay::GlobalNodeIdentification.define do
  object_from_id -> (node_id, ctx) do
    type_name, id = NodeIdentification.from_global_id(node_id)
    STAR_WARS_DATA[type_name][id]
  end

  type_from_object -> (object) do
    if object == :test_error
      :not_a_type
    elsif object.is_a?(Base)
      BaseType
    elsif STAR_WARS_DATA["Faction"].values.include?(object)
      Faction
    elsif STAR_WARS_DATA["Ship"].values.include?(object)
      Ship
    else
      nil
    end
  end
end

Ship = GraphQL::ObjectType.define do
  name "Ship"
  interfaces [NodeIdentification.interface]
  # Explict alternative to `global_id_field` helper:
  field :id, field: GraphQL::Relay::GlobalIdField.new("Ship")
  field :name, types.String
end

BaseType = GraphQL::ObjectType.define do
  name "Base"
  interfaces [NodeIdentification.interface]
  global_id_field :id
  field :name, types.String
  field :planet, types.String
end

# Use an optional block to add fields to the connection type:
BaseConnectionWithTotalCountType = BaseType.define_connection do
  name "BasesConnectionWithTotalCount"
  field :totalCount do
    type types.Int
    resolve -> (obj, args, ctx) { obj.object.count }
  end
end

class CustomBaseEdge < GraphQL::Relay::Edge
  def upcased_name
    node.name.upcase
  end
end

CustomBaseEdgeType = BaseType.define_edge do
  name "CustomBaseEdge"
  field :upcasedName, types.String, property: :upcased_name
  field :edgeClassName, types.String do
    resolve -> (obj, args, ctx) { obj.class.name }
  end
end

CustomEdgeBaseConnectionType = BaseType.define_connection(edge_class: CustomBaseEdge, edge_type: CustomBaseEdgeType) do
  name "CustomEdgeBaseConnection"

  field :totalCountTimes100 do
    type types.Int
    resolve -> (obj, args, ctx) { obj.object.count * 100 }
  end
end


Faction = GraphQL::ObjectType.define do
  name "Faction"
  interfaces [NodeIdentification.interface]
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
  connection :bases, BaseConnectionWithTotalCountType do
    # Resolve field should return an Array, the Connection
    # will do the rest!
    resolve -> (obj, args, ctx) {
      all_bases = Base.where(id: obj.bases)
      if args[:nameIncludes]
        all_bases = all_bases.where("name LIKE ?", "%#{args[:nameIncludes]}%")
      end
      all_bases
    }
    argument :nameIncludes, types.String
  end

  connection :basesClone, BaseType.connection_type
  connection :basesByName, BaseType.connection_type, property: :bases do
    argument :order, types.String, default_value: "name"
    resolve -> (obj, args, ctx) {
      if args[:order].present?
        obj.bases.order(args[:order])
      else
        obj.bases
      end
    }
  end

  connection :basesWithMaxLimitRelation, BaseType.connection_type, max_page_size: 2 do
    resolve -> (object, args, context) { Base.all }
  end

  connection :basesWithMaxLimitArray, BaseType.connection_type, max_page_size: 2 do
    resolve -> (object, args, context) { Base.all.to_a }
  end

  connection :basesAsSequelDataset, BaseConnectionWithTotalCountType do
    argument :nameIncludes, types.String
    resolve -> (obj, args, ctx) {
      all_bases = SequelBase.where(faction_id: obj.id)
      if args[:nameIncludes]
        all_bases = all_bases.where("name LIKE ?", "%#{args[:nameIncludes]}%")
      end
      all_bases
    }
  end

  connection :basesWithCustomEdge, CustomEdgeBaseConnectionType, property: :bases
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
  description "Add a ship to this faction"

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

  field :largestBase, BaseType do
    resolve -> (obj, args, ctx) { Base.find(3) }
  end

  field :node, field: NodeIdentification.field
end

MutationType = GraphQL::ObjectType.define do
  name "Mutation"
  # The mutation object exposes a field:
  field :introduceShip, field: IntroduceShipMutation.field
end

StarWarsSchema = GraphQL::Schema.new(query: QueryType, mutation: MutationType)
StarWarsSchema.node_identification = NodeIdentification
