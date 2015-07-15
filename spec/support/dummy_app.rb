require_relative './dummy_data'

EdibleInterface = GraphQL::Interface.new do |i, type|
  i.name "Edible"
  i.description "Something you can eat, yum"
  i.fields({
    fatContent: i.field(
      type: !type.Float,
      property: :non_existent_field_that_should_never_be_called,
      desc: "Percentage which is fat"),
  })
end

AnimalProductInterface = GraphQL::Interface.new do |i, type|
  i.name "AnimalProduct"
  i.description "Comes from an animal, no joke"
  i.fields({
    source: i.field(type: !type.String, desc: "Animal which produced this product"),
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

CheeseType = GraphQL::ObjectType.new do |t, type|
  t.name "Cheese"
  t.description "Cultured dairy product"
  t.interfaces [EdibleInterface, AnimalProductInterface]
  t.fields = {
    id:           t.field(type: !type.Int, desc: "Unique identifier"),
    flavor:       t.field(type: !type.String, desc: "Kind of cheese"),
    source:       t.field(type: !DairyAnimalEnum, desc: "Animal which produced the milk for this cheese"),
    similarCheeses: GraphQL::Field.new do |f|
      f.description "Cheeses like this one"
      f.type(t)
      f.arguments({source: t.arg(type: !type[!DairyAnimalEnum])})
      f.resolve -> (t, a, c) { CHEESES.values.find { |c| c.source == a["source"] } }
    end,
    fatContent:   t.field(type: !type.Float, desc: "Percentage which is milkfat", deprecation_reason: "Diet fashion has changed"),
  }
end

 MilkType = GraphQL::ObjectType.new do |t, type|
  t.name 'Milk'
  t.description "Dairy beverage"
  t.interfaces [EdibleInterface, AnimalProductInterface]
  t.fields = {
    id:           t.field(type: !type.Int, desc: "Unique identifier"),
    source:       t.field(type: DairyAnimalEnum, desc: "Animal which produced this milk"),
    fatContent:   t.field(type: !type.Float, desc: "Percentage which is milkfat"),
    flavors:      t.field(
          type: type[type.String],
          desc: "Chocolate, Strawberry, etc",
          args: {limit: t.arg({type: type.Int})}
        ),
  }
end

DairyProductUnion = GraphQL::Union.new(
  "DairyProduct",
  "Kinds of food made from milk",
  [MilkType, CheeseType]
)

DairyProductInputType = GraphQL::InputObjectType.new {|t, type|
  t.name "DairyProductInput"
  t.description "Properties for finding a dairy product"
  t.input_fields({
    source:     t.arg({type: DairyAnimalEnum}),
    fatContent: t.arg({type: type.Float}),
  })
}


class FetchField
  attr_reader :type, :arguments, :deprecation_reason
  attr_accessor :name
  def initialize(type:, data:)
    @type = type
    @data = data
    @arguments = {}
    @deprecation_reason = nil
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
  f.type EdibleInterface
  f.resolve -> (t, a, c) { MILKS[1] }
end


QueryType = GraphQL::ObjectType.new do |t|
  t.name "Query"
  t.description "Query root of the system"
  t.fields({
    cheese: FetchField.new(type: CheeseType, data: CHEESES),
    fromSource: SourceField,
    favoriteEdible: FavoriteField,
    searchDairy: GraphQL::Field.new { |f|
      f.name "searchDairy"
      f.description "Find dairy products matching a description"
      f.type !DairyProductUnion
      f.arguments({product: t.arg({type: DairyProductInputType})})
      f.resolve -> (t, a, c) {
        products = CHEESES.values + MILKS.values
        source =  a["product"]["source"]
        if !source.nil?
          products = products.select { |p| p.source == source }
        end
        products.first
      }
    },
    error: GraphQL::Field.new { |f|
      f.description "Raise an error"
      f.type GraphQL::STRING_TYPE
      f.resolve -> (t, a, c) { raise("This error was raised on purpose") }
    },
  })
end

GLOBAL_VALUES = []

MutationType = GraphQL::ObjectType.new do |t, type|
  t.name "Mutation"
  t.description "The root for mutations in this schema"
  t.fields({
    pushValue: GraphQL::Field.new { |f|
      f.description("Push a value onto a global array :D")
      f.type(!type[!type.Int])
      f.arguments(value: t.arg(type: !type.Int))
      f.resolve -> (o, args, ctx) {
        GLOBAL_VALUES << args["value"]
        GLOBAL_VALUES
      }
    }
  })
end
DummySchema = GraphQL::Schema.new(query: QueryType, mutation: MutationType)
