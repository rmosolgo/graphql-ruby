require 'spec_helper'

describe GraphQL::Schema::TypeReducer do
  let(:type_hash) { {} }
  let(:reducer) { GraphQL::Schema::TypeReducer.new(CheeseType, type_hash)}

  it 'finds types from a single type and its fields' do
    expected = {
      "Cheese" => CheeseType,
      "Integer" => GraphQL::INTEGER_TYPE,
      "String" => GraphQL::STRING_TYPE,
      "DairyAnimal" => DairyAnimalEnum,
    }
    assert_equal(expected.keys, reducer.result.keys)
    assert_equal(expected, reducer.result)
  end
end
