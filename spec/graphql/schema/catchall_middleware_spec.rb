# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::CatchallMiddleware do
  let(:schema) do
    Class.new(Dummy::Schema) do
      middleware GraphQL::Schema::CatchallMiddleware
    end
  end
  let(:result) { schema.execute(query_string) }
  let(:query_string) {%| query noMilk { error }|}

  if TESTING_RESCUE_FROM
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
end
