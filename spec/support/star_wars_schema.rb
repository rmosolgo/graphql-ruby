# Adapted from graphql-relay-js
# https://github.com/graphql/graphql-relay-js/blob/master/src/__tests__/starWarsSchema.js

Ship = GraphQL::ObjectType.define do
  name "Ship"
  interfaces [GraphQL::Relay::Node.interface]
  global_id_field :id
  field :name, types.String
end

BaseType = GraphQL::ObjectType.define do
  name "Base"
  interfaces [GraphQL::Relay::Node.interface]
  global_id_field :id
  field :name, types.String
  field :planet, types.String
end

# Use an optional block to add fields to the connection type:
BaseConnectionWithTotalCountType = BaseType.define_connection do
  name "BasesConnectionWithTotalCount"
  field :totalCount do
    type types.Int
    resolve ->(obj, args, ctx) { obj.nodes.count }
  end
end

class CustomBaseEdge < GraphQL::Relay::Edge
  def upcased_name
    node.name.upcase
  end

  def upcased_parent_name
    parent.name.upcase
  end
end

CustomBaseEdgeType = BaseType.define_edge do
  name "CustomBaseEdge"
  field :upcasedName, types.String, property: :upcased_name
  field :upcasedParentName, types.String, property: :upcased_parent_name
  field :edgeClassName, types.String do
    resolve ->(obj, args, ctx) { obj.class.name }
  end
end

CustomEdgeBaseConnectionType = BaseType.define_connection(edge_class: CustomBaseEdge, edge_type: CustomBaseEdgeType) do
  name "CustomEdgeBaseConnection"

  field :totalCountTimes100 do
    type types.Int
    resolve ->(obj, args, ctx) { obj.nodes.count * 100 }
  end

  field :fieldName, types.String, resolve: ->(obj, args, ctx) { obj.field.name }
end

Faction = GraphQL::ObjectType.define do
  name "Faction"
  interfaces [GraphQL::Relay::Node.interface]

  field :id, !types.ID, resolve: GraphQL::Relay::GlobalIdResolve.new(type: Faction)
  field :name, types.String
  connection :ships, Ship.connection_type do
    resolve ->(obj, args, ctx) {
      all_ships = obj.ships.map {|ship_id| STAR_WARS_DATA["Ship"][ship_id] }
      if args[:nameIncludes]
        all_ships = all_ships.select { |ship| ship.name.include?(args[:nameIncludes])}
      end
      all_ships
    }
    # You can define arguments here and use them in the connection
    argument :nameIncludes, types.String
  end
  connection :shipsWithMaxPageSize, Ship.connection_type, max_page_size: 2 do
    resolve ->(obj, args, ctx) {
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
    resolve ->(obj, args, ctx) {
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
    resolve ->(obj, args, ctx) {
      if args[:order].present?
        obj.bases.order(args[:order])
      else
        obj.bases
      end
    }
  end

  connection :basesWithMaxLimitRelation, BaseType.connection_type, max_page_size: 2 do
    resolve ->(object, args, context) { Base.all }
  end

  connection :basesWithMaxLimitArray, BaseType.connection_type, max_page_size: 2 do
    resolve ->(object, args, context) { Base.all.to_a }
  end

  connection :basesAsSequelDataset, BaseConnectionWithTotalCountType do
    argument :nameIncludes, types.String
    resolve ->(obj, args, ctx) {
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
  return_field :shipEdge, Ship.edge_type
  return_field :faction, Faction

  # Here's the mutation operation:
  resolve ->(root_obj, inputs, ctx) {
    faction_id = inputs["factionId"]
    ship = STAR_WARS_DATA.create_ship(inputs["shipName"], faction_id)
    faction = STAR_WARS_DATA["Faction"][faction_id]
    connection_class = GraphQL::Relay::BaseConnection.connection_for_nodes(faction.ships)
    ships_connection = connection_class.new(faction.ships, inputs)
    ship_edge = GraphQL::Relay::Edge.new(ship, ships_connection)
    { shipEdge: ship_edge, faction: faction }
  }
end

QueryType = GraphQL::ObjectType.define do
  name "Query"
  field :rebels, Faction do
    resolve ->(obj, args, ctx) { STAR_WARS_DATA["Faction"]["1"]}
  end

  field :empire, Faction do
    resolve ->(obj, args, ctx) { STAR_WARS_DATA["Faction"]["2"]}
  end

  field :largestBase, BaseType do
    resolve ->(obj, args, ctx) { Base.find(3) }
  end

  field :node, GraphQL::Relay::Node.field
end

MutationType = GraphQL::ObjectType.define do
  name "Mutation"
  # The mutation object exposes a field:
  field :introduceShip, field: IntroduceShipMutation.field
end

StarWarsSchema = GraphQL::Schema.define do
  query(QueryType)
  mutation(MutationType)

  resolve_type ->(object, ctx) {
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
  }

  object_from_id ->(node_id, ctx) do
    type_name, id = GraphQL::Schema::UniqueWithinType.decode(node_id)
    STAR_WARS_DATA[type_name][id]
  end

  id_from_object ->(object, type, ctx) do
    GraphQL::Schema::UniqueWithinType.encode(type.name, object.id)
  end
end
