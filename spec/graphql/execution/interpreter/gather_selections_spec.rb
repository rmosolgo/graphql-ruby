# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::Interpreter::GatherSelections do

  def get_yielded_selections(object, type, *query_args, **query_kwargs)
    query = GraphQL::Query.new(GatherSelectionsSchema, *query_args, **query_kwargs)
    sels = query.document.definitions.first.selections
    selections = GraphQL::Execution::Interpreter::GatherSelections.new(query, sels)
    results = []
    selections.gather_for(object, type) do |selections, is_array|
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

    query(Query)
  end

  it "yields simple selections" do
    expected_selections = [
      ["a",
      "b", # TODO not this because skipped
      "c",
      "d",
      # "e" This fails typecheck
      "f",
      # "g" This fails typecheck
      ]
      # TODO Runtime directives on fragments
    ]
    str = "{
      a @skip(if: false)
      b @skip(if: true)
      ... { c }
      ... on Test { d }
      ... on Other { e }
      ...F
      ...G
    }

    fragment F on Test {
      f
    }

    fragment G on Other {
      g
    }
    "

    assert_equal expected_selections, get_yielded_selections(:thing, GatherSelectionsSchema::TestType, str)
  end

end
