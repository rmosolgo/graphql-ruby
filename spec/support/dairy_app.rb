require_relative './dairy_data'

EdibleInterface = GraphQL::InterfaceType.define do
  name "Edible"
  description "Something you can eat, yum"
  field :fatContent, !types.Float, "Percentage which is fat", property: :bogus_property
end

AnimalProductInterface = GraphQL::InterfaceType.define do
  name "AnimalProduct"
  description "Comes from an animal, no joke"
  field :source, !types.String, "Animal which produced this product"
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
  description "Cultured dairy product"
  interfaces [EdibleInterface, AnimalProductInterface]

  # Can have (name, type, desc)
  field :id, !types.Int, "Unique identifier"
  field :flavor, !types.String, "Kind of Cheese"

  # Or can define by block:
  field :source do
    type(!DairyAnimalEnum)
    description("Animal which produced the milk for this cheese")
  end

  field :similarCheeses do
    type -> { CheeseType }
    description("Cheeses like this one")
    argument :source, !types[!DairyAnimalEnum]
    resolve -> (t, a, c) {
      CHEESES.values.find { |c| c.source == a["source"] }
    }
  end

  field :fatContent, property: :fat_content do
    type(!GraphQL::FLOAT_TYPE)
    description("Percentage which is milkfat")
    deprecation_reason("Diet fashion has changed")
  end
end

MilkType = GraphQL::ObjectType.define do
  name 'Milk'
  description "Dairy beverage"
  interfaces [EdibleInterface, AnimalProductInterface]
  field :id, !types.ID
  field :source, DairyAnimalEnum, "Animal which produced this milk"
  field :fatContent, !types.Float, "Percentage which is milkfat"
  field :flavors, types[types.String], "Chocolate, Strawberry, etc" do
    argument :limit, types.Int
  end
end

DairyType = GraphQL::ObjectType.define do
  name 'Dairy'
  description 'A farm where milk is harvested and cheese is produced'
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
  possible_types [MilkType, CheeseType]
end

DairyProductInputType = GraphQL::InputObjectType.define {
  name "DairyProductInput"
  description "Properties for finding a dairy product"
  input_field :source, DairyAnimalEnum
  input_field :fatContent, types.Float
}


class FetchField
  def self.create(type:, data:, id_type: !GraphQL::INT_TYPE)
    desc = "Find a #{type.name} by id"
    return_type = type
    GraphQL::Field.define do
      type(return_type)
      description(desc)
      argument :id, id_type

      resolve -> (t, a, c) { data[a["id"].to_i] }
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

      resolve -> (t, a, c) {data}
    end
  end
end

SourceFieldDefn = Proc.new {
  type GraphQL::ListType.new(of_type: CheeseType)
  description "Cheese from source"
  argument :source, !DairyAnimalEnum
  resolve -> (target, arguments, context) {
    CHEESES.values.select{ |c| c.source == arguments["source"] }
  }
}

FavoriteFieldDefn = Proc.new {
  description "My favorite food"
  type EdibleInterface
  resolve -> (t, a, c) { MILKS[1] }
}

QueryType = GraphQL::ObjectType.define do
  name "Query"
  description "Query root of the system"
  field :cheese, field: FetchField.create(type: CheeseType, data: CHEESES)
  field :milk, field: FetchField.create(type: MilkType, data: MILKS, id_type: !types.ID)
  field :dairy, field: SingletonField.create(type: DairyType, data: DAIRY)
  field :fromSource, &SourceFieldDefn
  field :favoriteEdible, &FavoriteFieldDefn
  field :searchDairy do
    description "Find dairy products matching a description"
    type !DairyProductUnion
    argument :product, DairyProductInputType
    resolve -> (t, a, c) {
      products = CHEESES.values + MILKS.values
      source =  a["product"][:source] # String or sym is ok
      if !source.nil?
        products = products.select { |p| p.source == source }
      end
      products.first
    }
  end

  field :error do
    description "Raise an error"
    type GraphQL::STRING_TYPE
    resolve -> (t, a, c) { raise("This error was raised on purpose") }
  end

  # To test possibly-null fields
  field :maybeNull, MaybeNullType do
    resolve -> (t, a, c) { OpenStruct.new(cheese: nil) }
  end
end

GLOBAL_VALUES = []

ReplaceValuesInputType = GraphQL::InputObjectType.define do
  name "ReplaceValuesInput"
  input_field :values, !types[!types.Int]
end

MutationType = GraphQL::ObjectType.define do
  name "Mutation"
  description "The root for mutations in this schema"
  field :pushValue, !types[!types.Int] do
    description("Push a value onto a global array :D")
    argument :value, !types.Int
    resolve -> (o, args, ctx) {
      GLOBAL_VALUES << args[:value]
      GLOBAL_VALUES
    }
  end

  field :replaceValues, !types[!types.Int] do
    description("Replace the global array with new values")
    argument :input, !ReplaceValuesInputType
    resolve -> (o, args, ctx) {
      GLOBAL_VALUES.clear
      GLOBAL_VALUES += args[:input][:values]
      GLOBAL_VALUES
    }
  end
end

DummySchema = GraphQL::Schema.new(query: QueryType, mutation: MutationType)
