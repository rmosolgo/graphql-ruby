# frozen_string_literal: true
require "spec_helper"

describe GraphQL::CoercionError do
  let(:result) { Dummy::Schema.execute(query_string, variables: provided_variables) }
  describe "extensions in CoercionError" do
    let(:query_string) {%|
      query searchMyDairy (
              $time: Time
            ) {
        searchDairy(expiresAfter: $time) {
          ... on Cheese {
            flavor
          }
        }
      }
      |}

    let(:provided_variables) { { "time" => "a" } }

    it "the error is inserted into the errors key with custom data set in `extensions`" do
      errors = result['errors']
      assert_includes errors, {
                        "message"=>"Variable time of type Time was provided invalid value",
                        "locations"=>[{"line"=>3, "column"=>15}],
                        "value"=>"a",
                        "extensions"=>{"error"=>"invalid_format"},
                        "problems"=>[{"path"=>[], "explanation"=>"cannot coerce to Float"}]
                      }

    end
  end
end