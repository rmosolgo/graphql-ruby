# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Relay::ConnectionInstrumentation do
  it "replaces the previous field definition" do
    test_type = GraphQL::ObjectType.define do
      name "Test"
      connection :tests, test_type.connection_type
    end

    assert_equal ["tests"], test_type.fields.keys
  end

  it "keeps a reference to the function" do
    conn_field = StarWars::Faction.graphql_definition.fields["shipsWithMaxPageSize"]
    assert_instance_of StarWars::ShipsWithMaxPageSize, conn_field.function
  end

  let(:build_schema) {
    test_type = nil

    test_field = GraphQL::Field.define do
      type(test_type.connection_type)
      property(:something)
    end

    test_type = GraphQL::ObjectType.define do
      name "Test"
      connection :tests, test_field
    end

    [
      test_field,
      GraphQL::Schema.define(query: test_type, raise_definition_error: true)
    ]
  }

  it "leaves the original field untouched" do
    test_field, test_schema = build_schema
    conn_field = test_schema.get_field(test_schema.query, "tests")

    assert_equal 0, test_field.arguments.length
    assert_equal 4, conn_field.arguments.length

    assert_instance_of GraphQL::Field::Resolve::MethodResolve, test_field.resolve_proc
    assert_instance_of GraphQL::Relay::ConnectionResolve, conn_field.resolve_proc
  end

  it "passes connection behaviors to redefinitions" do
    _test_field, test_schema = build_schema
    connection_field = test_schema.get_field(test_schema.query, "tests")
    redefined_connection_field = connection_field.redefine { argument "name", types.String }

    assert_equal 4, connection_field.arguments.size
    assert_equal 5, redefined_connection_field.arguments.size

    assert_instance_of GraphQL::Relay::ConnectionResolve, connection_field.resolve_proc
    assert_instance_of GraphQL::Relay::ConnectionResolve, redefined_connection_field.resolve_proc
  end

  describe "after_built_ins instrumentation" do
    it "has access to connection objects" do
      query_str = <<-GRAPHQL
      {
        rebels {
          ships {
            pageInfo {
              __typename
            }
          }
        }
      }
      GRAPHQL
      ctx = { before_built_ins: [], after_built_ins: [] }
      star_wars_query(query_str, {}, context: ctx)
      # The second item is different here:
      # Before the object is wrapped in a connection, the instrumentation sees `Array`
      assert_equal ["StarWars::FactionRecord", "Array", "GraphQL::Relay::ArrayConnection"], ctx[:before_built_ins]
      # After the object is wrapped in a connection, it sees the connection object
      assert_equal ["StarWars::Faction", "StarWars::ShipConnectionWithParentType", "GraphQL::Types::Relay::PageInfo"], ctx[:after_built_ins]
    end
  end
end
