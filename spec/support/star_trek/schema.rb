# frozen_string_literal: true
module StarTrek
  # Adapted from graphql-relay-js
  # https://github.com/graphql/graphql-relay-js/blob/master/src/__tests__/StarTrekSchema.js

  class Ship < GraphQL::Schema::Object
    implements GraphQL::Relay::Node.interface
    global_id_field :id
    field :name, String, null: true
    # Test cyclical connection types:
    field :ships, Ship.connection_type, null: false
  end

  class BaseType < GraphQL::Schema::Object
    graphql_name "Base"
    implements GraphQL::Relay::Node.interface
    global_id_field :id
    field :name, String, null: false, resolve: ->(obj, args, ctx) {
      LazyWrapper.new {
        if obj.id.nil?
          raise GraphQL::ExecutionError, "Boom!"
        else
          obj.name
        end
      }
    }
    field :sector, String, null: true
  end

  class BaseConnectionWithTotalCountType < GraphQL::Types::Relay::BaseConnection
    graphql_name "BasesConnectionWithTotalCount"
    edge_type(BaseType.edge_type)
    field :total_count, Integer, null: true

    def total_count
      object.nodes.count
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

  class CustomBaseEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(BaseType)
    graphql_name "CustomBaseEdge"
    field :upcased_name, String, null: true
    field :upcased_parent_name, String, null: true
    field :edge_class_name, String, null: true

    def edge_class_name
      object.class.name
    end
  end

  class CustomEdgeBaseConnectionType < GraphQL::Types::Relay::BaseConnection
    edge_type(CustomBaseEdgeType, edge_class: CustomBaseEdge)

    field :total_count_times_100, Integer, null: true
    def total_count_times_100
      obj.nodes.count * 100
    end

    field :field_name, String, null: true
    def field_name
      object.field.name
    end
  end

  # Example of GraphQL::Function used with the connection helper:
  class ShipsWithMaxPageSize < GraphQL::Function
    argument :nameIncludes, GraphQL::STRING_TYPE
    def call(obj, args, ctx)
      all_ships = obj.ships.map { |ship_id| StarTrek::DATA["Ship"][ship_id] }
      if args[:nameIncludes]
        all_ships = all_ships.select { |ship| ship.name.include?(args[:nameIncludes])}
      end
      all_ships
    end

    type Ship.connection_type
  end

  class ShipConnectionWithParentType < GraphQL::Types::Relay::BaseConnection
    edge_type(Ship.edge_type)
    graphql_name "ShipConnectionWithParent"
    field :parent_class_name, String, null: false
    def parent_class_name
      object.parent.class.name
    end
  end

  class Faction < GraphQL::Schema::Object
    implements GraphQL::Relay::Node.interface

    field :id, ID, null: false, resolve: GraphQL::Relay::GlobalIdResolve.new(type: Faction)
    field :name, String, null: true
    field :ships, ShipConnectionWithParentType, connection: true, max_page_size: 1000, null: true, resolve: ->(obj, args, ctx) {
      all_ships = obj.ships.map {|ship_id| StarTrek::DATA["Ship"][ship_id] }
      if args[:nameIncludes]
        case args[:nameIncludes]
        when "error"
          all_ships = GraphQL::ExecutionError.new("error from within connection")
        when "raisedError"
          raise GraphQL::ExecutionError.new("error raised from within connection")
        when "lazyError"
          all_ships = LazyWrapper.new { GraphQL::ExecutionError.new("lazy error from within connection") }
        when "lazyRaisedError"
          all_ships = LazyWrapper.new { raise GraphQL::ExecutionError.new("lazy raised error from within connection") }
        when "null"
          all_ships = nil
        when "lazyObject"
          prev_all_ships = all_ships
          all_ships = LazyWrapper.new { prev_all_ships }
        else
          all_ships = all_ships.select { |ship| ship.name.include?(args[:nameIncludes])}
        end
      end
      all_ships
    } do
      # You can define arguments here and use them in the connection
      argument :nameIncludes, String, required: false
    end

    field :shipsWithMaxPageSize, "Ships with max page size", max_page_size: 2, function: ShipsWithMaxPageSize.new

    field :bases, BaseConnectionWithTotalCountType, null: true, connection: true, resolve: ->(obj, args, ctx) {
      all_bases = obj.bases
      if args[:nameIncludes]
        all_bases = all_bases.where(name: Regexp.new(args[:nameIncludes]))
      end
      all_bases
    } do
      argument :nameIncludes, String, required: false
    end

    field :basesClone, BaseType.connection_type, null: true
    field :basesByName, BaseType.connection_type, null: true do
      argument :order, String, default_value: "name", required: false
    end
    def bases_by_name(order: nil)
      if order.present?
        @object.bases.order_by(name: order)
      else
        @object.bases
      end
    end

    field :basesWithMaxLimitRelation, BaseType.connection_type, null: true, max_page_size: 2, resolve: Proc.new { Base.all}
    field :basesWithMaxLimitArray, BaseType.connection_type, null: true, max_page_size: 2, resolve: Proc.new { Base.all.to_a }
    field :basesWithDefaultMaxLimitRelation, BaseType.connection_type, null: true, resolve: Proc.new { Base.all }
    field :basesWithDefaultMaxLimitArray, BaseType.connection_type, null: true, resolve: Proc.new { Base.all.to_a }
    field :basesWithLargeMaxLimitRelation, BaseType.connection_type, null: true, max_page_size: 1000, resolve: Proc.new { Base.all }

    field :basesWithCustomEdge, CustomEdgeBaseConnectionType, null: true, connection: true, resolve: ->(o, a, c) { LazyNodesWrapper.new(o.bases) }
  end

  class IntroduceShipMutation < GraphQL::Schema::RelayClassicMutation
    description "Add a ship to this faction"

    # Nested under `input` in the query:
    argument :ship_name, String, required: false
    argument :faction_id, ID, required: true

    # Result may have access to these fields:
    field :ship_edge, Ship.edge_type, null: true
    field :faction, Faction, null: true
    field :aliased_faction, Faction, hash_key: :aliased_faction, null: true

    def resolve(ship_name: nil, faction_id:)
      IntroduceShipFunction.new.call(object, {ship_name: ship_name, faction_id: faction_id}, context)
    end
  end

  class IntroduceShipFunction < GraphQL::Function
    description "Add a ship to this faction"

    argument :shipName, GraphQL::STRING_TYPE
    argument :factionId, !GraphQL::ID_TYPE

    type(GraphQL::ObjectType.define do
      name "IntroduceShipFunctionPayload"
      field :shipEdge, Ship.edge_type, hash_key: :shipEdge
      field :faction, Faction, hash_key: :shipEdge
    end)

    def call(obj, args, ctx)
      # support old and new args
      ship_name = args["shipName"] || args[:ship_name]
      faction_id = args["factionId"] || args[:faction_id]
      if ship_name == 'USS Voyager'
        GraphQL::ExecutionError.new("Sorry, USS Voyager ship is reserved")
      elsif ship_name == 'IKS Korinar'
        raise GraphQL::ExecutionError.new("🔥")
      elsif ship_name == 'Scimitar'
        LazyWrapper.new { raise GraphQL::ExecutionError.new("💥")}
      else
        ship = DATA.create_ship(ship_name, faction_id)
        faction = DATA["Faction"][faction_id]
        connection_class = GraphQL::Relay::BaseConnection.connection_for_nodes(faction.ships)
        ships_connection = connection_class.new(faction.ships, args)
        ship_edge = GraphQL::Relay::Edge.new(ship, ships_connection)
        result = {
          shipEdge: ship_edge,
          ship_edge: ship_edge, # support new-style, too
          faction: faction,
          aliased_faction: faction,
        }
        if args["shipName"] == "Slave II"
          LazyWrapper.new(result)
        else
          result
        end
      end
    end
  end

  IntroduceShipFunctionMutation = GraphQL::Relay::Mutation.define do
    # Used as the root for derived types:
    name "IntroduceShipFunction"
    function IntroduceShipFunction.new
  end

  # GraphQL-Batch knockoff
  class LazyLoader
    def self.defer(ctx, model, id)
      ids = ctx.namespace(:loading)[model] ||= []
      ids << id
      self.new(model: model, id: id, context: ctx)
    end

    def initialize(model:, id:, context:)
      @model = model
      @id = id
      @context = context
    end

    def value
      loaded = @context.namespace(:loaded)[@model] ||= {}
      if loaded.empty?
        ids = @context.namespace(:loading)[@model]
        # Example custom tracing
        @context.trace("lazy_loader", { ids: ids, model: @model}) do
          records = @model.where(id: ids)
          records.each do |record|
            loaded[record.id.to_s] = record
          end
        end
      end

      loaded[@id]
    end
  end

  class LazyWrapper
    def initialize(value = nil, &block)
      if block_given?
        @lazy_value = block
      else
        @value = value
      end
    end

    def value
      @resolved_value = @value || @lazy_value.call
    end
  end

  LazyNodesWrapper = Struct.new(:relation)
  class LazyNodesRelationConnection < GraphQL::Relay::RelationConnection
    def initialize(wrapper, *args)
      super(wrapper.relation, *args)
    end

    def edge_nodes
      LazyWrapper.new { super }
    end
  end

  GraphQL::Relay::BaseConnection.register_connection_implementation(LazyNodesWrapper, LazyNodesRelationConnection)

  class QueryType < GraphQL::Schema::Object
    graphql_name "Query"

    field :federation, Faction, null: true, resolve: ->(obj, args, ctx) { StarTrek::DATA["Faction"]["1"]}

    field :klingons, Faction, null: true, resolve: ->(obj, args, ctx) { StarTrek::DATA["Faction"]["2"]}

    field :romulans, Faction, null: true, resolve: ->(obj, args, ctx) { StarTrek::DATA["Faction"]["3"]}

    field :largestBase, BaseType, null: true, resolve: ->(obj, args, ctx) { Base.find(3) }

    field :newestBasesGroupedByFaction, BaseType.connection_type, null: true, resolve: ->(obj, args, ctx) {
      agg = Base.collection.aggregate([{
        "$group" => {
          "_id" => "$faction_id",
          "baseId" => { "$max" => "$_id" }
        }
      }])
      Base.
        in(id: agg.map { |doc| doc['baseId'] }).
        order_by(faction_id: -1)
    }

    field :basesWithNullName, BaseType.connection_type, null: false, resolve: ->(obj, args, ctx) {
      [OpenStruct.new(id: nil)]
    }

    field :node, field: GraphQL::Relay::Node.field

    custom_node_field = GraphQL::Relay::Node.field do
      resolve ->(_, _, _) { StarTrek::DATA["Faction"]["1"] }
    end
    field :nodeWithCustomResolver, field: custom_node_field

    field :nodes, field: GraphQL::Relay::Node.plural_field
    field :nodesWithCustomResolver, field: GraphQL::Relay::Node.plural_field(
      resolve: ->(_, _, _) { [StarTrek::DATA["Faction"]["1"], StarTrek::DATA["Faction"]["2"]] }
    )

    field :batchedBase, BaseType, null: true do
      argument :id, ID, required: true
    end

    def batched_base(id:)
      LazyLoader.defer(@context, Base, id)
    end
  end

  class MutationType < GraphQL::Schema::Object
    graphql_name "Mutation"
    field :introduceShip, mutation: IntroduceShipMutation
    # To hook up a Relay::Mutation
    field :introduceShipFunction, field: IntroduceShipFunctionMutation.field
  end

  class ClassNameRecorder
    def initialize(context_key)
      @context_key = context_key
    end

    def instrument(type, field)
      inner_resolve = field.resolve_proc
      key = @context_key
      field.redefine {
        resolve ->(o, a, c) {
          res = inner_resolve.call(o, a, c)
          if c[key]
            c[key] << res.class.name
          end
          res
        }
      }
    end
  end

  class Schema < GraphQL::Schema
    query(QueryType)
    mutation(MutationType)
    default_max_page_size 3

    def self.resolve_type(type, object, ctx)
      if object == :test_error
        :not_a_type
      elsif object.is_a?(Base)
        BaseType
      elsif DATA["Faction"].values.include?(object)
        Faction
      elsif DATA["Ship"].values.include?(object)
        Ship
      else
        nil
      end
    end

    def self.object_from_id(node_id, ctx)
      type_name, id = GraphQL::Schema::UniqueWithinType.decode(node_id)
      StarTrek::DATA[type_name][id]
    end

    def self.id_from_object(object, type, ctx)
      GraphQL::Schema::UniqueWithinType.encode(type.name, object.id)
    end

    lazy_resolve(LazyWrapper, :value)
    lazy_resolve(LazyLoader, :value)

    instrument(:field, ClassNameRecorder.new(:before_built_ins))
    instrument(:field, ClassNameRecorder.new(:after_built_ins), after_built_ins: true)
  end
end
