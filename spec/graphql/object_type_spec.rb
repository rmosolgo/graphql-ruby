require 'spec_helper'

describe GraphQL::ObjectType do
  let(:type) { CheeseType }

  it 'has a name' do
    assert_equal("Cheese", type.name)
    type.name = "Fromage"
    assert_equal("Fromage", type.name)
    type.name = "Cheese"
  end

  it 'has a description' do
    assert_equal(22, type.description.length)
  end

  it 'may have interfaces' do
    assert_equal([EdibleInterface, AnimalProductInterface], type.interfaces)
  end

  describe '.fields ' do
    it 'exposes fields' do
      field = type.fields["id"]
      assert_equal(GraphQL::TypeKinds::NON_NULL, field.type.kind)
      assert_equal(GraphQL::TypeKinds::SCALAR, field.type.of_type.kind)
    end

    it 'exposes defined field property' do
      field_without_prop = CheeseType.fields['flavor']
      field_with_prop = CheeseType.fields['fatContent']
      assert_equal(field_without_prop.property, nil)
      assert_equal(field_with_prop.property, :fat_content)
    end
  end
end
