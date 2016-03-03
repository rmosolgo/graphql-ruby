require "spec_helper"

describe GraphQL::StaticValidation::DirectivesAreInValidLocations do
  let(:query_string) {"
    query getCheese @skip(if: true) {
      okCheese: cheese(id: 1) {
        id @skip(if: true),
        source
        ... on Cheese @skip(if: true) {
          flavor
        }
      }
    }

    fragment whatever on Cheese @skip(if: true) {
      id
    }
  "}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, rules: [GraphQL::StaticValidation::DirectivesAreInValidLocations]) }
  let(:query) { GraphQL::Query.new(DummySchema, query_string) }
  let(:errors) { validator.validate(query) }

  describe "invalid directive locations" do
    it "makes errors for them" do
      expected = [
        {
          "message"=> "'@skip' can't be applied to queries (allowed: fields, fragment spreads, inline fragments)",
          "locations"=>[{"line"=>2, "column"=>21}]
        },
        {
          "message"=>"'@skip' can't be applied to fragment definitions (allowed: fields, fragment spreads, inline fragments)",
          "locations"=>[{"line"=>12, "column"=>33}]
        },
      ]
      assert_equal(expected, errors)
    end
  end
end
