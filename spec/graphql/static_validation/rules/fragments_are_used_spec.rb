require "spec_helper"

describe GraphQL::StaticValidation::FragmentsAreUsed do
  let(:query_string) {"
    query getCheese {
      name,
      ...cheeseFields
      ...undefinedFields
    }
    fragment cheeseFields on Cheese { fatContent }
    fragment unusedFields on Cheese { is, not, used }
  "}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, rules: [GraphQL::StaticValidation::FragmentsAreUsed]) }
  let(:query) { GraphQL::Query.new(DummySchema, query_string) }
  let(:errors) { validator.validate(query)[:errors] }

  it "adds errors for unused fragment definitions" do
    assert_includes(errors, {
      "message"=>"Fragment unusedFields was defined, but not used",
      "locations"=>[{"line"=>8, "column"=>5}],
      "path"=>[],
    })
  end

  it "adds errors for undefined fragment spreads" do
    assert_includes(errors, {
      "message"=>"Fragment undefinedFields was used, but not defined",
      "locations"=>[{"line"=>5, "column"=>7}],
      "path"=>["query getCheese", "... undefinedFields"]
    })
  end

  describe "queries that are comments" do
    let(:query_string) {%|
      # I am a comment.
    |}
    let(:document) { GraphQL.parse(query_string) }
    let(:result) { DummySchema.execute(document: document) }
    it "handles them gracefully" do
      assert_equal nil, result
    end
  end
end
