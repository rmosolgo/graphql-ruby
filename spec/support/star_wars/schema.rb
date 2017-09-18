# frozen_string_literal: true
module StarWars
  # Adapted from graphql-relay-js
  # https://github.com/graphql/graphql-relay-js/blob/master/src/__tests__/starWarsSchema.js

  Ship = GraphQL::ObjectType.define do
    name "Ship"
    interfaces [GraphQL::Relay::Node.interface]
    global_id_field :id
    field :name, types.String
    # Test cyclical connection types:
    connection :ships, Ship.connection_type
  end

  BaseType = GraphQL::ObjectType.define do
    name "Base"
    interfaces [GraphQL::Relay::Node.interface]
    global_id_field :id
    field :name, !types.String do
      resolve ->(obj, args, ctx) {
        LazyWrapper.new {
          if obj.id.nil?
            raise GraphQL::ExecutionError, "Boom!"
          else
            obj.name
          end
        }
      }
    end
    field :planet, types.String
  end

  # Use an optional block to add fields to the connection type:
  BaseConnectionWithTotalCountType = BaseType.define_connection(nodes_field: true) do
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

  CustomEdgeBaseConnectionType = BaseType.define_connection(edge_class: CustomBaseEdge, edge_type: CustomBaseEdgeType, nodes_field: true) do
    name "CustomEdgeBaseConnection"

    field :totalCountTimes100 do
      type types.Int
      resolve ->(obj, args, ctx) { obj.nodes.count * 100 }
    end

    field :fieldName, types.String, resolve: ->(obj, args, ctx) { obj.field.name }
  end

  # Example of GraphQL::Function used with the connection helper:
  class ShipsWithMaxPageSize < GraphQL::Function
    argument :nameIncludes, GraphQL::STRING_TYPE
    def call(obj, args, ctx)
      all_ships = obj.ships.map { |ship_id| StarWars::DATA["Ship"][ship_id] }
      if args[:nameIncludes]
        all_ships = all_ships.select { |ship| ship.name.include?(args[:nameIncludes])}
      end
      all_ships
    end

    type Ship.connection_type
  end

  ShipConnectionWithParentType = Ship.define_connection do
    name "ShipConnectionWithParent"
    field :parentClassName, !types.String do
      resolve ->(o, a, c) { o.parent.class.name }
    end
  end

  Faction = GraphQL::ObjectType.define do
    name "Faction"
    interfaces [GraphQL::Relay::Node.interface]

    field :id, !types.ID, resolve: GraphQL::Relay::GlobalIdResolve.new(type: Faction)
    field :name, types.String
    connection :ships, ShipConnectionWithParentType, max_page_size: 1000 do
      resolve ->(obj, args, ctx) {
        all_ships = obj.ships.map {|ship_id| StarWars::DATA["Ship"][ship_id] }
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
      }
      # You can define arguments here and use them in the connection
      argument :nameIncludes, types.String
    end

    connection :shipsWithMaxPageSize, max_page_size: 2, function: ShipsWithMaxPageSize.new

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

    connection :basesWithDefaultMaxLimitRelation, BaseType.connection_type do
      resolve ->(object, args, context) { Base.all }
    end

    connection :basesWithDefaultMaxLimitArray, BaseType.connection_type do
      resolve ->(object, args, context) { Base.all.to_a }
    end

    connection :basesWithLargeMaxLimitRelation, BaseType.connection_type, max_page_size: 1000 do
      resolve ->(object, args, context) { Base.all }
    end

    connection :basesAsSequelDataset, BaseConnectionWithTotalCountType, max_page_size: 1000 do
      argument :nameIncludes, types.String
      resolve ->(obj, args, ctx) {
        all_bases = SequelBase.where(faction_id: obj.id)
        if args[:nameIncludes]
          all_bases = all_bases.where(Sequel.like(:name, "%#{args[:nameIncludes]}%"))
        end
        all_bases
      }
    end

    connection :basesWithCustomEdge, CustomEdgeBaseConnectionType do
      resolve ->(o, a, c) {
        LazyNodesWrapper.new(o.bases)
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
    description "Add a ship to this faction"

    # Nested under `input` in the query:
    input_field :shipName, types.String
    input_field :factionId, !types.ID

    # Result may have access to these fields:
    return_field :shipEdge, Ship.edge_type
    return_field :faction, Faction
    return_field :aliasedFaction, Faction, property: :aliased_faction

    # Here's the mutation operation:
    resolve ->(root_obj, inputs, ctx) {
      IntroduceShipFunction.new.call(root_obj, inputs, ctx)
    }
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
      faction_id = args["factionId"]
      if args["shipName"] == 'Millennium Falcon'
        GraphQL::ExecutionError.new("Sorry, Millennium Falcon ship is reserved")
      elsif args["shipName"] == 'Leviathan'
        raise GraphQL::ExecutionError.new("🔥")
      elsif args["shipName"] == "Ebon Hawk"
        LazyWrapper.new { raise GraphQL::ExecutionError.new("💥")}
      else
        ship = DATA.create_ship(args["shipName"], faction_id)
        faction = DATA["Faction"][faction_id]
        connection_class = GraphQL::Relay::BaseConnection.connection_for_nodes(faction.ships)
        ships_connection = connection_class.new(faction.ships, args)
        ship_edge = GraphQL::Relay::Edge.new(ship, ships_connection)
        result = {
          shipEdge: ship_edge,
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
        GraphQL::Tracing.trace("lazy_loader", { ids: ids, model: @model}) do
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

  QueryType = GraphQL::ObjectType.define do
    name "Query"
    field :rebels, Faction do
      resolve ->(obj, args, ctx) { StarWars::DATA["Faction"]["1"]}
    end

    field :empire, Faction do
      resolve ->(obj, args, ctx) { StarWars::DATA["Faction"]["2"]}
    end

    field :largestBase, BaseType do
      resolve ->(obj, args, ctx) { Base.find(3) }
    end

    connection :newestBasesGroupedByFaction, BaseType.connection_type do
      resolve ->(obj, args, ctx) {
        Base
          .having('id in (select max(id) from bases group by faction_id)')
          .group(:id)
          .order('faction_id desc')
      }
    end

    connection :basesWithNullName, BaseType.connection_type do
      resolve ->(obj, args, ctx) {
        [OpenStruct.new(id: nil)]
      }
    end

    field :node, GraphQL::Relay::Node.field

    custom_node_field = GraphQL::Relay::Node.field do
      resolve ->(_, _, _) { StarWars::DATA["Faction"]["1"] }
    end
    field :nodeWithCustomResolver, custom_node_field

    field :nodes, GraphQL::Relay::Node.plural_field
    field :nodesWithCustomResolver, GraphQL::Relay::Node.plural_field(
      resolve: ->(_, _, _) { [StarWars::DATA["Faction"]["1"], StarWars::DATA["Faction"]["2"]] }
    )

    field :batchedBase, BaseType do
      argument :id, !types.ID
      resolve ->(o, a, c) {
        LazyLoader.defer(c, Base, a["id"])
      }
    end
  end

  MutationType = GraphQL::ObjectType.define do
    name "Mutation"
    # The mutation object exposes a field:
    field :introduceShip, field: IntroduceShipMutation.field
    field :introduceShipFunction, IntroduceShipFunctionMutation.field
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

  Schema = GraphQL::Schema.define do
    query(QueryType)
    mutation(MutationType)
    default_max_page_size 3

    resolve_type ->(type, object, ctx) {
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
    }

    object_from_id ->(node_id, ctx) do
      type_name, id = GraphQL::Schema::UniqueWithinType.decode(node_id)
      StarWars::DATA[type_name][id]
    end

    id_from_object ->(object, type, ctx) do
      GraphQL::Schema::UniqueWithinType.encode(type.name, object.id)
    end

    lazy_resolve(LazyWrapper, :value)
    lazy_resolve(LazyLoader, :value)

    instrument(:field, ClassNameRecorder.new(:before_built_ins))
    instrument(:field, ClassNameRecorder.new(:after_built_ins), after_built_ins: true)
  end
end
