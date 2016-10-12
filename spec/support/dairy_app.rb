require_relative "./dairy_data"

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
end

AnimalProductInterface = GraphQL::InterfaceType.define do
  name "AnimalProduct"
  description "Comes from an animal, no joke"
  field :source, !types.String, "Animal which produced this product"
end

BeverageUnion = GraphQL::UnionType.define do
  name "Beverage"
  description "Something you can drink"
  possible_types [MilkType]
end

DairyAnimalEnum = GraphQL::EnumType.define do
  name "DairyAnimal"
  description "An animal which can yield milk"
  value("COW",    "Animal with black and white spots", value: 1)
  value("GOAT",   "Animal with horns")
  value("SHEEP",  "Animal with wool")
  value("YAK",    "Animal with long hair", deprecation_reason: "Out of fashion")
end

CheeseType = GraphQL::ObjectType.define do
  name "Cheese"
  class_names ["Cheese"]
  description "Cultured dairy product"
  interfaces [EdibleInterface, AnimalProductInterface, LocalProductInterface]

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
    argument :source, !types[!DairyAnimalEnum], default_value: [1]
    resolve ->(t, a, c) {
      # get the strings out:
      sources = a["source"]
      if sources.include?("YAK")
        raise NoSuchDairyError.new("No cheeses are made from Yak milk!")
      else
        CHEESES.values.find { |c| sources.include?(c.source) }
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
  interfaces [EdibleInterface, AnimalProductInterface, LocalProductInterface]
  field :id, !types.ID
  field :source, DairyAnimalEnum, "Animal which produced this milk", hash_key: :source
  field :origin, !types.String, "Place the milk comes from"
  field :flavors, types[types.String], "Chocolate, Strawberry, etc" do
    argument :limit, types.Int
    resolve ->(milk, args, ctx) {
      args[:limit] ? milk.flavors.first(args[:limit]) : milk.flavors
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

DairyProductUnion = GraphQL::UnionType.define do
  name "DairyProduct"
  description "Kinds of food made from milk"
  # Test that these forms of declaration still work:
  possible_types ["MilkType", -> { CheeseType }]
end

CowType = GraphQL::ObjectType.define do
  name "Cow"
  description "A farm where milk is harvested and cheese is produced"
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

DairyProductInputType = GraphQL::InputObjectType.define {
  name "DairyProductInput"
  description "Properties for finding a dairy product"
  input_field :source, !DairyAnimalEnum do
    # ensure we can define description in block
    description "Where it came from"
  end

  input_field :originDairy, types.String, "Dairy which produced it", default_value: "Sugar Hollow Dairy" do
    description   "Ignored because arg takes precedence"
    default_value "Ignored because keyword arg takes precedence"
  end

  input_field :fatContent, types.Float, "How much fat it has" do
    # ensure we can define default in block
    default_value 0.3
  end

  # ensure default can be false
  input_field :organic, types.Boolean, default_value: false
}

DeepNonNullType = GraphQL::ObjectType.define do
  name "DeepNonNull"
  field :nonNullInt, !types.Int do
    argument :returning, types.Int
    resolve ->(obj, args, ctx) { args[:returning] }
  end

  field :deepNonNull, DeepNonNullType.to_non_null_type do
    resolve ->(obj, args, ctx) { :deepNonNull }
  end
end

class FetchField
  def self.create(type:, data:, id_type: !GraphQL::INT_TYPE)
    desc = "Find a #{type.name} by id"
    return_type = type
    GraphQL::Field.define do
      type(return_type)
      description(desc)
      argument :id, id_type

      resolve ->(t, a, c) {
        id_string = a["id"].to_s # Cheese has Int type, Milk has ID type :(
        id, item = data.find { |id, item| id.to_s == id_string }
        item
      }
    end
  end
end

class SingletonField
  def self.create(type:, data:)
    desc = "Find the only #{type.name}"
    return_type = type
    GraphQL::Field.define do
      type(return_type)
      description(desc)

      resolve ->(t, a, c) {data}
    end
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
  field :cheese, field: FetchField.create(type: CheeseType, data: CHEESES)
  field :milk, field: FetchField.create(type: MilkType, data: MILKS, id_type: !types.ID)
  field :dairy, field: SingletonField.create(type: DairyType, data: DAIRY)
  field :fromSource, &SourceFieldDefn
  field :favoriteEdible, FavoriteFieldDefn
  field :cow, field: SingletonField.create(type: CowType, data: COW)
  field :searchDairy do
    description "Find dairy products matching a description"
    type !DairyProductUnion
    # This is a list just for testing 😬
    argument :product, types[DairyProductInputType], default_value: [{"source" => "SHEEP"}]
    resolve ->(t, args, c) {
      source = args["product"][0][:source] # String or Sym is ok
      products = CHEESES.values + MILKS.values
      if !source.nil?
        products = products.select { |pr| pr.source == source }
      end
      products.first
    }
  end

  field :allDairy, types[DairyProductUnion] do
    argument :executionErrorAtIndex, types.Int
    resolve ->(obj, args, ctx) {
      result = CHEESES.values + MILKS.values
      result[args[:executionErrorAtIndex]] = GraphQL::ExecutionError.new("missing dairy") if args[:executionErrorAtIndex]
      result
    }
  end

  field :allEdible, types[EdibleInterface] do
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

  # To test possibly-null fields
  field :maybeNull, MaybeNullType do
    resolve ->(t, a, c) { OpenStruct.new(cheese: nil) }
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

DairyAppMutationType = GraphQL::ObjectType.define do
  name "Mutation"
  description "The root for mutations in this schema"
  field :pushValue, !types[!types.Int] do
    description("Push a value onto a global array :D")
    argument :value, !types.Int
    resolve ->(o, args, ctx) {
      GLOBAL_VALUES << args[:value]
      GLOBAL_VALUES
    }
  end

  field :replaceValues, !types[!types.Int] do
    description("Replace the global array with new values")
    argument :input, !ReplaceValuesInputType
    resolve ->(o, args, ctx) {
      GLOBAL_VALUES.clear
      GLOBAL_VALUES.push(*args[:input][:values])
      GLOBAL_VALUES
    }
  end
end

SubscriptionType = GraphQL::ObjectType.define do
  name "Subscription"
  field :test, types.String do
    resolve ->(o, a, c) { "Test" }
  end
end

DummySchema = GraphQL::Schema.define do
  query DairyAppQueryType
  mutation DairyAppMutationType
  subscription SubscriptionType
  max_depth 5
  orphan_types [HoneyType, BeverageUnion]

  rescue_from(NoSuchDairyError) { |err| err.message  }

  resolve_type ->(obj, ctx) {
    DummySchema.types[obj.class.name]
  }
end
