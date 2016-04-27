require "spec_helper"

describe GraphQL::StaticValidation::DirectivesAreDefined do
  let(:query_string) {"
    query getCheese {
      okCheese: cheese(id: 1) {
        id @skip(if: true),
        source @nonsense(if: false)
        ... on Cheese {
          flavor @moreNonsense
        }
      }
    }
  "}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, rules: [GraphQL::StaticValidation::DirectivesAreDefined]) }
  let(:query) { GraphQL::Query.new(DummySchema, query_string) }
  let(:errors) { validator.validate(query) }

  describe "non-existent directives" do
    it "makes errors for them" do
      expected = [
        {
          "message"=>"Directive @nonsense is not defined",
          "locations"=>[{"line"=>5, "column"=>16}]
        }, {
          "message"=>"Directive @moreNonsense is not defined",
          "locations"=>[{"line"=>7, "column"=>18}]
        }
      ]
      assert_equal(expected, errors)
    end
  end
end
