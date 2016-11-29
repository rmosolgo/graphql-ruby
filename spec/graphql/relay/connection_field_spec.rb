# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Relay::ConnectionField do
  it "replaces the previous field definition" do
    test_type = GraphQL::ObjectType.define do
      name "Test"
      connection :tests, test_type.connection_type
    end

    assert_equal ["tests"], test_type.fields.keys
  end

  it "leaves the original field untouched" do
    test_type = nil

    test_field = GraphQL::Field.define do
      type(test_type.connection_type)
      property(:something)
    end

    test_type = GraphQL::ObjectType.define do
      name "Test"
      connection :tests, test_field
    end

    conn_field = test_type.fields["tests"]

    assert_equal 0, test_field.arguments.length
    assert_equal 4, conn_field.arguments.length

    assert_instance_of GraphQL::Field::Resolve::MethodResolve, test_field.resolve_proc
    assert_instance_of GraphQL::Relay::ConnectionResolve, conn_field.resolve_proc
  end

  it "passes connection behaviors to redefinitions" do
    test_type = GraphQL::ObjectType.define do
      name "Test"
      connection :tests, test_type.connection_type
    end

    connection_field = test_type.fields["tests"]
    redefined_connection_field = connection_field.redefine { argument "name", types.String }

    assert_equal 4, connection_field.arguments.size
    assert_equal 5, redefined_connection_field.arguments.size

    assert_instance_of GraphQL::Relay::ConnectionResolve, connection_field.resolve_proc
    assert_instance_of GraphQL::Relay::ConnectionResolve, redefined_connection_field.resolve_proc
  end
end
