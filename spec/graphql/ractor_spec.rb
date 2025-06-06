# frozen_string_literal: true
require "spec_helper"

describe "Use with Ractors" do
  class RactorExampleSchema < GraphQL::Schema
    class Query < GraphQL::Schema::Object
      field :i, Int, fallback_value: 1
    end
    query(Query)
    validate_timeout(nil) # Timeout doesn't support Ractor yet?
    use GraphQL::Schema::Visibility, preload: true, dynamic: false, profiles: {
      nil => {}
    }

    extend GraphQL::Schema::RactorShareable
  end

  it "can access some basic GraphQL objects" do
    assert_equal({ "data" => { "__typename" => "Query" } }, RactorExampleSchema.execute("{ __typename }"))

    ractor = Ractor.new do
      query = GraphQL::Query.new(RactorExampleSchema, "{ __typename}", validate: false )
      Ractor.yield(query.class.name)
      result = query.result.to_h
      Ractor.yield(result)
    end
    assert_equal "GraphQL::Query", ractor.take
    assert_equal({"data" => {"__typename" => "Query"}}, ractor.take)
  end

  it "doesn't poison other schemas" do
    new_schema = Class.new(GraphQL::Schema) do
      q = Class.new(GraphQL::Schema::Object) {
        graphql_name("Query")
        field :f, Float
      }
      query(q)
    end

    assert_equal "Query", new_schema.execute("{ __typename }")["data"]["__typename"]
  end
end
