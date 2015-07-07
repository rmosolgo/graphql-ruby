require_relative './dummy_data'
Edible = :edible
Meltable = :meltable

class CheeseType < GraphQL::Type
  type_name "Cheese"
  description "Cultured dairy product"
  interfaces [Edible, Meltable]
  self.fields = {
    flavor:   field.string!(:flavor, "The flavor of ice cream"),
    creamery: field.string(:creamery, "The name of the place where the ice cream was made"),
  }
end

class MilkType < GraphQL::Type
  type_name "Milk"
  description "Dairy beverage, served cold"
  interfaces [Edible]
  self.fields = {
    # fat_content: field.float!(:fat_content)
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

class QueryType < GraphQL::Type
  type_name "Query"
  description "Query root of the system"
  self.fields = {
    cheese: FetchField.new(type: CheeseType, model: Cheese, data: CHEESES)
  }
end

DummySchema = GraphQL::Schema.new(query: QueryType, mutation: nil)
