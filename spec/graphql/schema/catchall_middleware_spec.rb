# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::CatchallMiddleware do
  let(:result) { Dummy::Schema.execute(query_string) }
  let(:query_string) {%| query noMilk { error }|}

  before do
    Dummy::Schema.middleware << GraphQL::Schema::CatchallMiddleware
  end

  after do
    Dummy::Schema.middleware.delete(GraphQL::Schema::CatchallMiddleware)
  end

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
