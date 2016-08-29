require "spec_helper"

describe GraphQL::Argument do
  it "is validated at schema build-time" do
    query_type = GraphQL::ObjectType.define do
      name "Query"
      field :invalid, types.Boolean do
        argument :invalid, types.Float, default_value: ["123"]
      end
    end

    err = assert_raises(GraphQL::Schema::InvalidTypeError) {
      schema = GraphQL::Schema.define(query: query_type)
      schema.types
    }

    expected_error = %|Query is invalid: field "invalid" argument "invalid" default value ["123"] is not valid for type Float|
    assert_equal expected_error, err.message
  end

  it "accepts proc type" do
    argument = GraphQL::Argument.define(name: :favoriteFood, type: -> { GraphQL::STRING_TYPE })
    assert_equal GraphQL::STRING_TYPE, argument.type
  end
end
