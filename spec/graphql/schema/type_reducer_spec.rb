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

  describe 'when a schema has multiple types with the same name' do
    let(:type_1) {
      GraphQL::ObjectType.define do
        name "MyType"
      end
    }
    let(:type_2) {
      GraphQL::ObjectType.define do
        name "MyType"
      end
    }
    it 'raises an error' do
      assert_raises(RuntimeError) {
        GraphQL::Schema::TypeReducer.find_all([type_1, type_2])
      }
    end
  end

  describe 'when getting a type which doesnt exist' do
    it 'raises an error' do
      type_map = GraphQL::Schema::TypeReducer.find_all([])
      assert_raises(RuntimeError) { type_map["SomeType"] }
    end
  end
end
