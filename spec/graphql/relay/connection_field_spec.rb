require "spec_helper"

describe GraphQL::Relay::ConnectionField do
  it "replaces the previous field definition" do
    test_type = GraphQL::ObjectType.define do
      name "Test"
      connection :tests, test_type.connection_type
    end

    assert_equal ["tests"], test_type.fields.keys
  end
end
