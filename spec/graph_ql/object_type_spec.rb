require 'spec_helper'

describe GraphQL::ObjectType do
  let(:type) { CheeseType }

  it 'has a name' do
    assert_equal("Cheese", type.name)
    type.name("Fromage")
    assert_equal("Fromage", type.name)
    type.name("Cheese")
  end

  it 'has a description' do
    assert_equal(22, type.description.length)
  end

  it 'may have interfaces' do
    assert_equal([EdibleInterface, AnimalProductInterface], type.interfaces)
  end

  it 'becomes non-null with !' do
    non_null_type = !type
    assert_equal(GraphQL::TypeKinds::NON_NULL, non_null_type.kind)
    assert_equal(type, non_null_type.of_type)
    assert_equal(GraphQL::TypeKinds::NON_NULL, (!GraphQL::STRING_TYPE).kind)
  end

  it 'can be compared' do
    assert_equal(!GraphQL::INT_TYPE, !GraphQL::INT_TYPE)
    refute_equal(!GraphQL::FLOAT_TYPE, GraphQL::FLOAT_TYPE)
    assert_equal(
      GraphQL::ListType.new(of_type: MilkType),
      GraphQL::ListType.new(of_type: MilkType)
    )
    refute_equal(
      GraphQL::ListType.new(of_type: MilkType),
      GraphQL::ListType.new(of_type: !MilkType)
    )
  end

  describe '.fields ' do
    it 'exposes fields' do
      field = type.fields["id"]
      assert_equal(GraphQL::TypeKinds::NON_NULL, field.type.kind)
      assert_equal(GraphQL::TypeKinds::SCALAR, field.type.of_type.kind)
    end
  end
end
