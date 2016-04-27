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
  let(:errors) { validator.validate(query) }

  it "adds errors for unused fragment definitions" do
    assert_includes(errors, {"message"=>"Fragment unusedFields was defined, but not used", "locations"=>[{"line"=>8, "column"=>5}]})
  end

  it "adds errors for undefined fragment spreads" do
    assert_includes(errors, {"message"=>"Fragment undefinedFields was used, but not defined", "locations"=>[{"line"=>5, "column"=>7}]})
  end
end
