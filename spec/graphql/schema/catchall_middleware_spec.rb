# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::CatchallMiddleware do
  let(:schema) do
    Class.new(Dummy::Schema) do
      query_execution_strategy(GraphQL::Execution::Execute)
      self.interpreter = false
      middleware GraphQL::Schema::CatchallMiddleware
    end
  end
  let(:result) { schema.graphql_definition.execute(query_string) }
  let(:query_string) {%| query noMilk { error }|}

  describe "rescuing errors" do
    let(:errors) { query.context.errors }

    it "turns into error messages" do
      expected = {
        "data" => { "error" => nil },
        "errors"=> [
          {
            "message"=>"Internal error",
            "locations"=>[{"line"=>1, "column"=>17}],
            "path"=>["error"]
          },
        ]
      }
      assert_equal(expected, result)
    end
  end
end
