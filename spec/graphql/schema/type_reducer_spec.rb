require 'spec_helper'

describe GraphQL::Schema::TypeReducer do
  it 'finds types from a single type and its fields' do
    reducer = GraphQL::Schema::TypeReducer.new(CheeseType, {})
    expected = {
      "Cheese" => CheeseType,
      "Float" => GraphQL::FLOAT_TYPE,
      "String" => GraphQL::STRING_TYPE,
      "DairyAnimal" => DairyAnimalEnum,
      "Int" => GraphQL::INT_TYPE,
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

  it 'finds types from nested InputObjectTypes' do
    type_child = GraphQL::InputObjectType.define do
      name "InputTypeChild"
      input_field :someField, GraphQL::STRING_TYPE
    end

    type_parent = GraphQL::InputObjectType.define do
      name "InputTypeParent"
      input_field :child, type_child
    end

    reducer = GraphQL::Schema::TypeReducer.new(type_parent, {})
    expected = {
      "InputTypeParent" => type_parent,
      "InputTypeChild" => type_child,
      "String" => GraphQL::STRING_TYPE
    }
    assert_equal(expected, reducer.result)
  end

  describe 'when a type is invalid' do
    let(:invalid_type) {
      GraphQL::ObjectType.define do
        name "InvalidType"
        field :someField
      end
    }

    let(:another_invalid_type) {
      GraphQL::ObjectType.define do
        name "AnotherInvalidType"
        field :someField, String
      end
    }

    it 'raises an InvalidTypeError when passed nil' do
      reducer = GraphQL::Schema::TypeReducer.new(invalid_type, {})
      assert_raises(GraphQL::Schema::InvalidTypeError) { reducer.result }
    end

    it 'raises an InvalidTypeError when passed an object that isnt a GraphQL::BaseType' do
      reducer = GraphQL::Schema::TypeReducer.new(another_invalid_type, {})
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
