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
    assert_equal([:edible, :meltable], type.interfaces)
  end

  describe '.fields ' do
    let(:flavor_field) { type.fields["flavor"] }
    it 'exposes fields' do
      assert_equal(GraphQL::NonNullField, flavor_field.class)
    end
  end
end
