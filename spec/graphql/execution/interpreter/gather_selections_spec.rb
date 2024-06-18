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
      [
        # TODO these are moved up because they don't have conditions on them.
        # But it would be better to preserve their order.
        "b2",
        "c",
        "a",
        # "b", @skip
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

end
