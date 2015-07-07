require_relative './dummy_data'
Edible = :edible
Meltable = :meltable

CheeseType = GraphQL::Type.new do
  type_name "Cheese"
  description "Cultured dairy product"
  interfaces [Edible, Meltable]
  self.fields = {
    id:           !field.integer(:id, "Unique identifier"),
    flavor:       !field.string(:flavor, "Kind of cheese"),
    fat_content:  !field.float(:fat_content, "Percentage which is milkfat")
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

QueryType = GraphQL::Type.new do
  type_name "Query"
  description "Query root of the system"
  self.fields = {
    cheese: FetchField.new(type: CheeseType, model: Cheese, data: CHEESES)
  }
end

DummySchema = GraphQL::Schema.new(query: QueryType, mutation: nil)
