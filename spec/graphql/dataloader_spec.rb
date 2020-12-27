# frozen_string_literal: true
require "spec_helper"

describe "fiber data loading" do
  class FiberSchema < GraphQL::Schema
    DATA = {
      "1" => "Apple",
      "2" => "Broccoli",
      "3" => "Carrot",
    }

    class Loader

    end

    class Query < GraphQL::Schema::Object
      field :item, String, null: true do
        argument :id, ID, required: true
      end

      def item(id:)
        ids = context[:ids] ||= []
        ids << id
        context.yield_graphql
        # ^ Somehow GraphQL-Ruby calls other fields during this time
        data = context[:data] ||= {}
        if context[:ids] && context[:ids].any?
          loads = context[:loads] ||= []
          ids = context[:ids]
          loads << ids
          context[:ids] = nil
          ids.each { |load_id| data[load_id] = DATA[load_id] }
        end
        data[id]
      end
    end

    query(Query)

    use GraphQL::Analysis::AST
    use GraphQL::Execution::Interpreter
  end

  it "batch-loads" do
    context = {}
    res = FiberSchema.execute <<-GRAPHQL, context: context
    {
      i1: item(id: 1)
      i2: item(id: 2)
    }
    GRAPHQL
    assert_equal [["1", "2"]], context[:loads]
    assert_nil context[:ids]
    expected_data = {
      "i1" => "Apple",
      "i2" => "Broccoli",
    }
    assert_equal(expected_data, res["data"])
  end
end
