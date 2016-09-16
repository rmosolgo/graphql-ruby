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

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DairySchema, rules: [GraphQL::StaticValidation::DirectivesAreDefined]) }
  let(:query) { GraphQL::Query.new(DairySchema, query_string) }
  let(:errors) { validator.validate(query)[:errors] }

  describe "non-existent directives" do
    it "makes errors for them" do
      expected = [
        {
          "message"=>"Directive @nonsense is not defined",
          "locations"=>[{"line"=>5, "column"=>16}],
          "path"=>["query getCheese", "okCheese", "source"],
        }, {
          "message"=>"Directive @moreNonsense is not defined",
          "locations"=>[{"line"=>7, "column"=>18}],
          "path"=>["query getCheese", "okCheese", "... on Cheese", "flavor"],
        }
      ]
      assert_equal(expected, errors)
    end
  end
end
