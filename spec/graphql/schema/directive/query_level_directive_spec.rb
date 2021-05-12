# frozen_string_literal: true
require "spec_helper"

describe "Query level Directive" do
  class QueryDirectiveSchema < GraphQL::Schema
    class InitInt < GraphQL::Schema::Directive
      locations(GraphQL::Schema::Directive::QUERY)
      argument(:val, Integer, "Initial integer value.", required: true)

      def self.resolve(obj, args, ctx)
        ctx[:int] = args[:val]
        yield
      end
    end

    class Query < GraphQL::Schema::Object
      field :int, Integer, null: false

      def int
        context[:int] ||= 0
        context[:int] += 1
      end
    end

    directive(InitInt)
    query(Query)
  end

  it "returns an error if directive is not on the query level" do
    str = 'query TestDirective {
      int1: int @initInt(val: 10)
      int2: int
    }
    '

    res = QueryDirectiveSchema.execute(str)

    expected_errors = [
      {
        "message" => "'@initInt' can't be applied to fields (allowed: queries)",
        "locations" => [{ "line" => 2, "column" => 17 }],
        "path" => ["query TestDirective", "int1"],
        "extensions" => { "code" => "directiveCannotBeApplied", "targetName" => "fields", "name" => "initInt" }
      }
    ]
    assert_equal(expected_errors, res["errors"])
  end

  it "runs on the query level" do
    str = 'query TestDirective @initInt(val: 10) {
      int1: int
      int2: int
    }
    '

    res = QueryDirectiveSchema.execute(str)
    assert_equal({ "int1" => 11, "int2" => 12 }, res["data"])
  end
end
