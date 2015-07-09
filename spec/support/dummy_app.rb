require_relative './dummy_data'

Edible = :edible
# Edible = GraphQL::Interface.new do
#   description "Something you can eat, yum"
#   self.fields = {
#     fat_content: !field.float("Percentage which is fat"),
#   }
# end

Meltable = :meltable

DairyAnimalEnum = GraphQL::Enum.new("DairyAnimal", ["COW", "GOAT", "SHEEP"])

CheeseType = GraphQL::ObjectType.new do
  name "Cheese"
  description "Cultured dairy product"
  interfaces [Edible, Meltable]
  self.fields = {
    id:           field(type: !type.Int, desc: "Unique identifier"),
    flavor:       field(type: !type.String, desc: "Kind of cheese"),
    source:       field(type: !DairyAnimalEnum, desc: "Animal which produced the milk for this cheese"),
    fatContent:   field(type: !type.Float, desc: "Percentage which is milkfat"),
  }
end

MilkType = GraphQL::ObjectType.new do
  name 'Milk'
  description "Dairy beverage"
  interfaces [Edible]
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

DairyProductUnion = GraphQL::Union.new("DairyProduct", [MilkType, CheeseType])

class FetchField < GraphQL::AbstractField
  attr_reader :type
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

class SourceField < GraphQL::AbstractField
  def type
    GraphQL::ListType.new(of_type: CheeseType)
  end
  def description; "Cheese from source"; end
  def resolve(target, arguments, context)
    CHEESES.values.select{ |c| c.source == arguments["source"] }
  end
end

class FavoriteField < GraphQL::AbstractField
  def initialize(returning:)
    @returning = returning
  end
  def description; "My favorite dairy product"; end
  def type; DairyProductUnion; end
  def resolve(t, a, c); @returning; end
end

QueryType = GraphQL::ObjectType.new do
  name "Query"
  description "Query root of the system"
  self.fields = {
    cheese: FetchField.new(type: CheeseType, data: CHEESES),
    fromSource: SourceField.new,
    favoriteDiary: FavoriteField.new(returning: MILKS[1]),
  }
end

DummySchema = GraphQL::Schema.new(query: QueryType, mutation: nil)
