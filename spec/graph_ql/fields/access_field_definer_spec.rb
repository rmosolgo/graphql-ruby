require 'spec_helper'

describe GraphQL::AccessFieldDefiner do
  let(:definer) { GraphQL::AccessFieldDefiner.new}

  it 'makes fields with the given type, property and description' do
    name_field = definer.string(:name, "My name")
    assert_equal("My name", name_field.description)
    assert_equal(GraphQL::STRING_TYPE, name_field.type)
    assert_equal(:name, name_field.property)
  end

  it 'makes non-null fields'
  it 'makes list fields'
end
