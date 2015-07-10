require 'spec_helper'

describe GraphQL::Schema::TypeReducer do
  it 'finds types from a single type and its fields' do
    reducer = GraphQL::Schema::TypeReducer.new(CheeseType, {})
    expected = {
      "Cheese" => CheeseType,
      "Int" => GraphQL::INT_TYPE,
      "String" => GraphQL::STRING_TYPE,
      "DairyAnimal" => DairyAnimalEnum,
      "Float" => GraphQL::FLOAT_TYPE,
      "Edible" => Edible,
      "Milk" => MilkType,
      "AnimalProduct" => AnimalProduct,
    }
    assert_equal(expected.keys, reducer.result.keys)
    assert_equal(expected, reducer.result)
  end

  it 'finds type from arguments' do
    reducer = GraphQL::Schema::TypeReducer.new(QueryType, {})
    assert_equal(DairyProductInputType, reducer.result["DairyProductInput"])
  end
end
