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
      "Edible" => EdibleInterface,
      "Milk" => MilkType,
      "ID" => GraphQL::ID_TYPE,
      "AnimalProduct" => AnimalProductInterface,
    }
    assert_equal(expected.keys, reducer.result.keys)
    assert_equal(expected, reducer.result)
  end

  it 'finds type from arguments' do
    reducer = GraphQL::Schema::TypeReducer.new(QueryType, {})
    assert_equal(DairyProductInputType, reducer.result["DairyProductInput"])
  end

  describe 'when a type is invalid' do
    let(:invalid_type) {
      GraphQL::ObjectType.define do
        name "InvalidType"
        field :someField
      end
    }
    it 'raises an InvalidTypeError' do
      reducer = GraphQL::Schema::TypeReducer.new(invalid_type, {})
      assert_raises(GraphQL::Schema::InvalidTypeError) { reducer.result }
    end
  end
end
