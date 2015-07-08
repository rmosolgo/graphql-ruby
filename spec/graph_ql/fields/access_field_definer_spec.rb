require 'spec_helper'

describe GraphQL::AccessFieldDefiner do
  let(:definer) { GraphQL::AccessFieldDefiner.new}

  it 'gets the type from the method name' do
    name_field = definer.string(:name, "My name")
    assert_equal("My name", name_field.description)
    assert_equal(GraphQL::STRING_TYPE, name_field.type)
    assert_equal(:name, name_field.property)
  end

  it 'accepts object types' do
    dairy_animal_field = definer.of_type(DairyAnimalEnum, :source, "Animal which produced this")
    assert_equal(DairyAnimalEnum, dairy_animal_field.type)
  end

  it 'makes non-null fields'
  it 'makes list fields'
end
