require 'spec_helper'

describe GraphQL::Type do
  let(:type) { CheeseType }

  it 'has a name' do
    assert_equal("Cheese", type.type_name)
    type.type_name("Fromage")
    assert_equal("Fromage", type.type_name)
  end

  it 'has a description' do
    assert_equal(22, type.description.length)
  end

  it 'may have interfaces' do
    assert_equal([:edible, :meltable], type.interfaces)
  end

  describe '.fields ' do
    let(:flavor_field) { type.fields["flavor"] }
    let(:creamery_field) { type.fields["creamery"]}
    it 'exposes fields' do
      assert_equal(GraphQL::NonNullField, flavor_field.class)
      assert_equal(GraphQL::AccessField, creamery_field.class)
    end
  end
end
