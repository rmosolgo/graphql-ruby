require 'spec_helper'

describe GraphQL::TypeField do
  let(:schema) { OpenStruct.new(types: {"Cheese" => :cheese})}
  let(:type_field) { GraphQL::TypeField.new(schema) }

  it 'returns types from the schema' do
    cheese_type = type_field.resolve(nil, {"name" => "Cheese"}, nil)
    assert_equal(:cheese, cheese_type)
  end
end
