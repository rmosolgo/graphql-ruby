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
      schema = GraphQL::Schema.define(query: query_type, query_execution_strategy: DEFAULT_EXEC_STRATEGY)
      schema.types
    }

    expected_error = %|Query is invalid: field "invalid" argument "invalid" default value ["123"] is not valid for type Float|
    assert_includes err.message, expected_error
  end

  it "accepts proc type" do
    argument = GraphQL::Argument.define(name: :favoriteFood, type: -> { GraphQL::STRING_TYPE })
    assert_equal GraphQL::STRING_TYPE, argument.type
  end
end
