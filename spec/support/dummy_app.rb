require_relative './dummy_data'

Edible = GraphQL::Interface.new do
  name "Edible"
  description "Something you can eat, yum"
  fields({
    fatContent: field(
      type: !type.Float,
      property: :non_existent_field_that_should_never_be_called,
      desc: "Percentage which is fat"),
  })
end

AnimalProduct = GraphQL::Interface.new do
  name "AnimalProduct"
  description "Comes from an animal, no joke"
  fields({
    source: field(type: !type.String, desc: "Animal which produced this product"),
  })
end

DairyAnimalEnum = GraphQL::Enum.new do |e|
  e.name "DairyAnimal"
  e.description "An animal which can yield milk"
  e.value("COW",    "Animal with black and white spots")
  e.value("GOAT",   "Animal with horns")
  e.value("SHEEP",  "Animal with wool")
  e.value("YAK",    "Animal with long hair", deprecation_reason: "Out of fashion")
end

CheeseType = GraphQL::ObjectType.new do
  name "Cheese"
  description "Cultured dairy product"
  interfaces [Edible, AnimalProduct]
  self.fields = {
    id:           field(type: !type.Int, desc: "Unique identifier"),
    flavor:       field(type: !type.String, desc: "Kind of cheese"),
    source:       field(type: !DairyAnimalEnum, desc: "Animal which produced the milk for this cheese"),
    fatContent:   field(type: !type.Float, desc: "Percentage which is milkfat", deprecation_reason: "Diet fashion has changed"),
  }
end

MilkType = GraphQL::ObjectType.new do
  name 'Milk'
  description "Dairy beverage"
  interfaces [Edible, AnimalProduct]
  self.fields = {
    id:           field(type: !type.Int, desc: "Unique identifier"),
    source:       field(type: DairyAnimalEnum, desc: "Animal which produced this milk"),
    fatContent:   field(type: !type.Float, desc: "Percentage which is milkfat"),
    flavors:      field(
          type: type[type.String],
          desc: "Chocolate, Strawberry, etc",
          args: {limit: {type: type.Int}}
        ),
  }
end

DairyProductUnion = GraphQL::Union.new(
  "DairyProduct",
  "Kinds of food made from milk",
  [MilkType, CheeseType]
)

DairyProductInputType = GraphQL::InputObjectType.new {
  name "DairyProductInput"
  description "Properties for finding a dairy product"
  input_fields({
    source:     arg({type: DairyAnimalEnum}),
    fatContent: arg({type: type.Float}),
  })
}


class FetchField < GraphQL::AbstractField
  attr_reader :type
  attr_accessor :name
  def initialize(type:, data:)
    @type = type
    @data = data
  end

  def description
    "Find a #{@type.name} by id"
  end

  def resolve(target, arguments, context)
    @data[arguments["id"]]
  end
end

SourceField = GraphQL::Field.new do |f|
  f.type GraphQL::ListType.new(of_type: CheeseType)
  f.description "Cheese from source"
  f.resolve -> (target, arguments, context) {
    CHEESES.values.select{ |c| c.source == arguments["source"] }
  }
end

FavoriteField = GraphQL::Field.new do |f|
  f.description "My favorite food"
  f.type Edible
  f.resolve -> (t, a, c) { MILKS[1] }
end


QueryType = GraphQL::ObjectType.new do
  name "Query"
  description "Query root of the system"
  fields({
    cheese: FetchField.new(type: CheeseType, data: CHEESES),
    fromSource: SourceField,
    favoriteEdible: FavoriteField,
    searchDairy: GraphQL::Field.new { |f|
      f.name "searchDairy"
      f.description "Find dairy products matching a description"
      f.type DairyProductUnion
      f.arguments({product: {type: DairyProductInputType}})
      f.resolve -> (t, a, c) {
        products = CHEESES.values + MILKS.values
        source =  a["product"]["source"]
        if !source.nil?
          products = products.select { |p| p.source == source }
        end
        products.first
      }
    }
  })
end

GLOBAL_VALUES = []

MutationType = GraphQL::ObjectType.new do
  name "Mutation"
  description "The root for mutations in this schema"
  fields({
    pushValue: GraphQL::Field.new { |f|
      f.description("Push a value onto a global array :D")
      f.type(!type[!type.Int])
      f.arguments(value: arg(type: !type.Int))
      f.resolve -> (o, args, ctx) {
        GLOBAL_VALUES << args["value"]
        GLOBAL_VALUES
      }
    }
  })
end
DummySchema = GraphQL::Schema.new(query: QueryType, mutation: MutationType)
