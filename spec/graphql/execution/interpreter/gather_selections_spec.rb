# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::Interpreter::GatherSelections do

  def get_yielded_selections(object, type, *query_args, **query_kwargs)
    query = GraphQL::Query.new(GatherSelectionsSchema, *query_args, **query_kwargs)
    sels = query.document.definitions.first.selections
    gql_result = GraphQL::Execution::Interpreter::Runtime::GraphQLResultHash.new(
      nil,
      type,
      object,
      nil,
      false,
      sels,
      false
    )
    selections = GraphQL::Execution::Interpreter::GatherSelections.new(query)
    results = []
    selections.each_gathered_selections(gql_result) do |selections, is_array|
      results << selections.keys
    end
    results
  end

  class GatherSelectionsSchema < GraphQL::Schema
    class TestType < GraphQL::Schema::Object
      field :something, String
    end

    class OtherType < GraphQL::Schema::Object
      field :something, String
    end

    class Query < GraphQL::Schema::Object
      field :test_type, TestType
      field :other_type, OtherType
    end

    class Capitalize < GraphQL::Schema::Directive
      def self.resolve(obj, args, ctx)
        result = yield
        result.upcase
      end
    end

    query(Query)
    directive(Capitalize)
  end

  it "yields simple selections" do
    expected_selections = [
      [
        "b2",
        "c",
        "a",
        # "b", @skip
        "b3",
        "d",
        # "e" This fails typecheck
        "f",
        # "g" This fails typecheck,
        # "h", @skip
        "i"
      ]
      # TODO Runtime directives on fragments
    ]
    str = "{
      a @skip(if: false)
      b @skip(if: true)
      b2
      b3 @capitalize
      ... { c }
      ... on Test { d }
      ... on Other { e }
      ...F
      ...G
      ...H @skip(if: true)
      ...I @skip(if: false)
    }

    fragment F on Test { f }
    fragment G on Other { g }
    fragment H on Test { h }
    fragment I on Test { i }
    "

    assert_equal expected_selections, get_yielded_selections(:thing, GatherSelectionsSchema::TestType, str)
  end

  it "yields selections grouped by directive" do
    str = <<~GRAPHQL
      {
        ... @capitalize { a b }
        c
        d
        e @capitalize
      }
    GRAPHQL

    expected_selections = [
      ["c", "d"],
      ["a", "b", :graphql_directives],
    ]
    assert_equal expected_selections, get_yielded_selections(:thing, GatherSelectionsSchema::TestType, str)
  end
end
