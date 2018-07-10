# frozen_string_literal: true
require "graphql"
require_relative "./data"
module Dummy
  class NoSuchDairyError < StandardError; end

  GraphQL::Field.accepts_definitions(joins: GraphQL::Define.assign_metadata_key(:joins))
  GraphQL::BaseType.accepts_definitions(class_names: GraphQL::Define.assign_metadata_key(:class_names))

  LocalProductInterface = GraphQL::InterfaceType.define do
    name "LocalProduct"
    description "Something that comes from somewhere"
    field :origin, !types.String, "Place the thing comes from"
  end

  EdibleInterface = GraphQL::InterfaceType.define do
    name "Edible"
    description "Something you can eat, yum"
    field :fatContent, !types.Float, "Percentage which is fat"
    field :origin, !types.String, "Place the edible comes from"
    field :selfAsEdible, EdibleInterface, resolve: ->(o, a, c) { o }
  end

  EdibleAsMilkInterface = EdibleInterface.redefine do
    name "EdibleAsMilk"
    description "Milk :+1:"
    resolve_type ->(obj, ctx) { MilkType }
  end

  AnimalProductInterface = GraphQL::InterfaceType.define do
    name "AnimalProduct"
    description "Comes from an animal, no joke"
    field :source, !DairyAnimalEnum, "Animal which produced this product"
  end

  BeverageUnion = GraphQL::UnionType.define do
    name "Beverage"
    description "Something you can drink"
    possible_types [MilkType]
  end

  DairyAnimalEnum = GraphQL::EnumType.define do
    name "DairyAnimal"
    description "An animal which can yield milk"
    value("COW",      "Animal with black and white spots", value: 1)
    value("DONKEY",   "Animal with fur", value: :donkey)
    value("GOAT",     "Animal with horns")
    value("REINDEER", "Animal with horns", value: 'reindeer')
    value("SHEEP",    "Animal with wool")
    value("YAK",      "Animal with long hair", deprecation_reason: "Out of fashion")
  end

  CheeseType = GraphQL::ObjectType.define do
    name "Cheese"
    class_names ["Cheese"]
    description "Cultured dairy product"
    interfaces [EdibleInterface, EdibleAsMilkInterface, AnimalProductInterface, LocalProductInterface]

    # Can have (name, type, desc)
    field :id, !types.Int, "Unique identifier"
    field :flavor, !types.String, "Kind of Cheese"
    field :origin, !types.String, "Place the cheese comes from"

    field :source, !DairyAnimalEnum,
      "Animal which produced the milk for this cheese"

    # Or can define by block, `resolve ->` should override `property:`
    field :similarCheese, CheeseType, "Cheeses like this one", property: :this_should_be_overriden  do
      # metadata test
      joins [:cheeses, :milks]
      argument :source, !types[!DairyAnimalEnum]
      argument :nullableSource, types[!DairyAnimalEnum], default_value: [1]
      resolve ->(t, a, c) {
        # get the strings out:
        sources = a["source"]
        if sources.include?("YAK")
          raise NoSuchDairyError.new("No cheeses are made from Yak milk!")
        else
          CHEESES.values.find { |cheese| sources.include?(cheese.source) }
        end
      }
    end

    field :nullableCheese, CheeseType, "Cheeses like this one" do
      argument :source, types[!DairyAnimalEnum]
      resolve ->(t, a, c) { raise("NotImplemented") }
    end

    field :deeplyNullableCheese, CheeseType, "Cheeses like this one" do
      argument :source, types[types[DairyAnimalEnum]]
      resolve ->(t, a, c) { raise("NotImplemented") }
    end

    # Keywords can be used for definition methods
    field :fatContent,
      property: :fat_content,
      type: !GraphQL::FLOAT_TYPE,
      description: "Percentage which is milkfat",
      deprecation_reason: "Diet fashion has changed"
  end

  MilkType = GraphQL::ObjectType.define do
    name "Milk"
    description "Dairy beverage"
    interfaces [EdibleInterface, EdibleAsMilkInterface, AnimalProductInterface, LocalProductInterface]
    field :id, !types.ID
    field :source, !DairyAnimalEnum, "Animal which produced this milk", hash_key: :source
    field :origin, !types.String, "Place the milk comes from"
    field :flavors, types[types.String], "Chocolate, Strawberry, etc" do
      argument :limit, types.Int
      resolve ->(milk, args, ctx) {
        args[:limit] ? milk.flavors.first(args.limit) : milk.flavors
      }
    end
    field :executionError do
      type GraphQL::STRING_TYPE
      resolve ->(t, a, c) { raise(GraphQL::ExecutionError, "There was an execution error") }
    end

    field :allDairy, -> { types[DairyProductUnion] } do
      resolve ->(obj, args, ctx) { CHEESES.values + MILKS.values }
    end
  end

  SweetenerInterface = GraphQL::InterfaceType.define do
    name "Sweetener"
    field :sweetness, types.Int
  end

  # No actual data; This type is an "orphan", only accessible through Interfaces
  HoneyType = GraphQL::ObjectType.define do
    name "Honey"
    description "Sweet, dehydrated bee barf"
    field :flowerType, types.String, "What flower this honey came from"
    interfaces [EdibleInterface, AnimalProductInterface, SweetenerInterface]
  end

  DairyType = GraphQL::ObjectType.define do
    name "Dairy"
    description "A farm where milk is harvested and cheese is produced"
    field :id, !types.ID
    field :cheese, CheeseType
    field :milks, types[MilkType]
  end

  MaybeNullType = GraphQL::ObjectType.define do
    name "MaybeNull"
    description "An object whose fields return nil"
    field :cheese, CheeseType
  end

  TracingScalarType = GraphQL::ObjectType.define do
    name "TracingScalar"
    description "An object which has traced scalars"

    field :traceNil, types.Int
    field :traceFalse, types.Int, trace: false
    field :traceTrue, types.Int, trace: true
  end

  DairyProductUnion = GraphQL::UnionType.define do
    name "DairyProduct"
    description "Kinds of food made from milk"
    # Test that these forms of declaration still work:
    possible_types ["Dummy::MilkType", -> { CheeseType }]
  end

  CowType = GraphQL::ObjectType.define do
    name "Cow"
    description "A bovine animal that produces milk"
    field :id, !types.ID
    field :name, types.String
    field :last_produced_dairy, DairyProductUnion

    field :cantBeNullButIs do
      type !GraphQL::STRING_TYPE
      resolve ->(t, a, c) { nil }
    end

    field :cantBeNullButRaisesExecutionError do
      type !GraphQL::STRING_TYPE
      resolve ->(t, a, c) { raise GraphQL::ExecutionError, "BOOM" }
    end
  end

  GoatType = GraphQL::ObjectType.define do
    name "Goat"
    description "An caprinae animal that produces milk"
    field :id, !types.ID
    field :name, types.String
    field :last_produced_dairy, DairyProductUnion
  end

  AnimalUnion = GraphQL::UnionType.define do
    name "Animal"
    description "Species of living things"
    possible_types [CowType, GoatType]
  end

  AnimalAsCowUnion = GraphQL::UnionType.define do
    name "AnimalAsCow"
    description "All animals go mooooo!"
    possible_types [CowType]
    resolve_type ->(obj, ctx) {
      CowType
    }
  end

  ResourceOrderType = GraphQL::InputObjectType.define {
    name "ResourceOrderType"
    description "Properties used to determine ordering"

    argument :direction, !types.String do
      description "ASC or DESC"
    end
  }

  DairyProductInputType = GraphQL::InputObjectType.define {
    name "DairyProductInput"
    description "Properties for finding a dairy product"
    input_field :source, !DairyAnimalEnum do
      # ensure we can define description in block
      description "Where it came from"
    end

    input_field :originDairy, types.String, "Dairy which produced it", default_value: "Sugar Hollow Dairy"

    input_field :fatContent, types.Float, "How much fat it has" do
      # ensure we can define default in block
      default_value 0.3
    end

    # ensure default can be false
    input_field :organic, types.Boolean, default_value: false

    input_field :order_by, -> { ResourceOrderType }, default_value: { direction: 'ASC' }
  }

  DeepNonNullType = GraphQL::ObjectType.define do
    name "DeepNonNull"
    field :nonNullInt, !types.Int do
      argument :returning, types.Int
      resolve ->(obj, args, ctx) { args.returning }
    end

    field :deepNonNull, DeepNonNullType.to_non_null_type do
      resolve ->(obj, args, ctx) { :deepNonNull }
    end
  end

  TimeType = GraphQL::ScalarType.define do
    name "Time"
    description "Time since epoch in seconds"

    coerce_input ->(value, ctx) do
      begin
        Time.at(Float(value))
      rescue ArgumentError
        raise GraphQL::CoercionError, 'cannot coerce to Float'
      end
    end

    coerce_result ->(value, ctx) { value.to_f }
  end

  class FetchItem < GraphQL::Function
    attr_reader :type, :description, :arguments

    def initialize(type:, data:, id_type: !GraphQL::INT_TYPE)
      @type = type
      @data = data
      @description = "Find a #{type.name} by id"
      @arguments = self.class.arguments.merge({"id" => GraphQL::Argument.define(name: "id", type: id_type)})
    end

    def call(obj, args, ctx)
      id_string = args["id"].to_s # Cheese has Int type, Milk has ID type :(
      _id, item = @data.find { |id, _item| id.to_s == id_string }
      item
    end
  end

  class GetSingleton < GraphQL::Function
    attr_reader :description, :type

    def initialize(type:, data:)
      @description = "Find the only #{type.name}"
      @type = type
      @data = data
    end

    def call(obj, args, ctx)
      @data
    end
  end

  SourceFieldDefn = Proc.new {
    type GraphQL::ListType.new(of_type: CheeseType)
    description "Cheese from source"
    argument :source, DairyAnimalEnum, default_value: 1
    resolve ->(target, arguments, context) {
      CHEESES.values.select{ |c| c.source == arguments["source"] }
    }
  }

  FavoriteFieldDefn = GraphQL::Field.define do
    name "favoriteEdible"
    description "My favorite food"
    type EdibleInterface
    resolve ->(t, a, c) { MILKS[1] }
  end

  DairyAppQueryType = GraphQL::ObjectType.define do
    name "Query"
    description "Query root of the system"
    field :root, types.String do
      resolve ->(root_value, args, c) { root_value }
    end
    field :cheese, function: FetchItem.new(type: CheeseType, data: CHEESES)
    field :milk, function: FetchItem.new(type: MilkType, data: MILKS, id_type: !types.ID)
    field :dairy, function: GetSingleton.new(type: DairyType, data: DAIRY)
    field :fromSource, &SourceFieldDefn
    field :favoriteEdible, FavoriteFieldDefn
    field :cow, function: GetSingleton.new(type: CowType, data: COWS[1])
    field :searchDairy do
      description "Find dairy products matching a description"
      type !DairyProductUnion
      # This is a list just for testing 😬
      argument :product, types[DairyProductInputType], default_value: [{"source" => "SHEEP"}]
      argument :expiresAfter, TimeType
      resolve ->(t, args, c) {
        source = args["product"][0][:source] # String or Sym is ok
        products = CHEESES.values + MILKS.values
        if !source.nil?
          products = products.select { |pr| pr.source == source }
        end
        products.first
      }
    end

    field :allAnimal, !types[AnimalUnion] do
      resolve ->(obj, args, ctx) { COWS.values + GOATS.values }
    end

    field :allAnimalAsCow, !types[AnimalAsCowUnion] do
      resolve ->(obj, args, ctx) { COWS.values + GOATS.values }
    end

    field :allDairy, types[DairyProductUnion] do
      argument :executionErrorAtIndex, types.Int
      resolve ->(obj, args, ctx) {
        result = CHEESES.values + MILKS.values
        result[args.executionErrorAtIndex] = GraphQL::ExecutionError.new("missing dairy") if args.executionErrorAtIndex
        result
      }
    end

    field :allEdible, types[EdibleInterface] do
      resolve ->(obj, args, ctx) { CHEESES.values + MILKS.values }
    end

    field :allEdibleAsMilk, types[EdibleAsMilkInterface] do
      resolve ->(obj, args, ctx) { CHEESES.values + MILKS.values }
    end

    field :error do
      description "Raise an error"
      type GraphQL::STRING_TYPE
      resolve ->(t, a, c) { raise("This error was raised on purpose") }
    end

    field :executionError do
      type GraphQL::STRING_TYPE
      resolve ->(t, a, c) { raise(GraphQL::ExecutionError, "There was an execution error") }
    end

    field :valueWithExecutionError do
      type !GraphQL::INT_TYPE
      resolve ->(t, a, c) {
        c.add_error(GraphQL::ExecutionError.new("Could not fetch latest value"))
        return 0
      }
    end

    field :multipleErrorsOnNonNullableField do
      type !GraphQL::STRING_TYPE
      resolve ->(t, a, c) {
        [GraphQL::ExecutionError.new("This is an error message for some error."),
         GraphQL::ExecutionError.new("This is another error message for a different error.")]
      }
    end

    field :executionErrorWithOptions do
      type GraphQL::INT_TYPE
      resolve ->(t, a, c) {
        GraphQL::ExecutionError.new("Permission Denied!", options: { "code" => "permission_denied" })
      }
    end

    field :executionErrorWithExtensions do
      type GraphQL::INT_TYPE
      resolve ->(t, a, c) {
        GraphQL::ExecutionError.new("Permission Denied!", extensions: { "code" => "permission_denied" })
      }
    end

    # To test possibly-null fields
    field :maybeNull, MaybeNullType do
      resolve ->(t, a, c) { OpenStruct.new(cheese: nil) }
    end

    field :tracingScalar, TracingScalarType do
      resolve ->(o, a, c) do
        OpenStruct.new(
          traceNil: 2,
          traceFalse: 3,
          tracetrue: 5,
        )
      end
    end

    field :deepNonNull, !DeepNonNullType do
      resolve ->(o, a, c) { :deepNonNull }
    end
  end

  GLOBAL_VALUES = []

  ReplaceValuesInputType = GraphQL::InputObjectType.define do
    name "ReplaceValuesInput"
    input_field :values, !types[!types.Int]
  end

  PushValueField = GraphQL::Field.define do
    name :pushValue
    type !types[!types.Int]
    description("Push a value onto a global array :D")
    argument :value, !types.Int, as: :val
    resolve ->(o, args, ctx) {
      GLOBAL_VALUES << args.val
      GLOBAL_VALUES
    }
  end

  class DairyAppMutationType < GraphQL::Schema::Object
    graphql_name "Mutation"
    description "The root for mutations in this schema"
    # Test the `field:` compatibility option
    field :pushValue, field: PushValueField

    field :replaceValues, [Integer], "Replace the global array with new values", null: false do
      argument :input, ReplaceValuesInputType, required: true
    end

    def replace_values(input:)
      GLOBAL_VALUES.clear
      GLOBAL_VALUES.concat(input["values"])
      GLOBAL_VALUES
    end
  end

  SubscriptionType = GraphQL::ObjectType.define do
    name "Subscription"
    field :test, types.String do
      resolve ->(o, a, c) { "Test" }
    end
  end

  class Schema < GraphQL::Schema
    query DairyAppQueryType
    mutation DairyAppMutationType
    subscription SubscriptionType
    max_depth 5
    orphan_types [HoneyType, BeverageUnion]

    rescue_from(NoSuchDairyError) { |err| err.message  }

    def self.resolve_type(type, obj, ctx)
      Schema.types[obj.class.name.split("::").last]
    end
  end
end
