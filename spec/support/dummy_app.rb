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
    id:           !field.integer(:id, "Unique identifier"),
    flavor:       !field.string(:flavor, "Kind of cheese"),
    source:       !field(DairyAnimalEnum, :source, "Animal which produced the milk for this cheese"),
    fat_content:  !field.float(:fat_content, "Percentage which is milkfat"),
  }
end

class FetchField < GraphQL::AbstractField
  attr_reader :type
  def initialize(type:, model:, data:)
    @type = type
    @model = model
    @data = data
  end

  def description
    "Find a #{@model.type_name} by id"
  end

  def resolve(target, arguments, context)
    @data[arguments["id"]]
  end
end

class SourceField < GraphQL::AbstractField
  def type
    GraphQL::ListType.new(of_type: CheeseType)
  end

  def resolve(target, arguments, context)
    CHEESES.values.select{ |c| c.source == arguments["source"] }
  end
end

QueryType = GraphQL::ObjectType.new do
  name "Query"
  description "Query root of the system"
  self.fields = {
    cheese: FetchField.new(type: CheeseType, model: Cheese, data: CHEESES),
    fromSource: SourceField.new,
  }
end

DummySchema = GraphQL::Schema.new(query: QueryType, mutation: nil)
