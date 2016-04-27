require "spec_helper"

describe GraphQL::StaticValidation::FieldsHaveAppropriateSelections do
  let(:query_string) {"
    query getCheese {
      okCheese: cheese(id: 1) { fatContent, similarCheese(source: YAK) { source } }
      missingFieldsCheese: cheese(id: 1)
      illegalSelectionCheese: cheese(id: 1) { id { something, ... someFields } }
    }
  "}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, rules: [GraphQL::StaticValidation::FieldsHaveAppropriateSelections]) }
  let(:query) { GraphQL::Query.new(DummySchema, query_string) }
  let(:errors) { validator.validate(query) }

  it "adds errors for selections on scalars" do
    assert_equal(2, errors.length)

    illegal_selection_error = {
      "message"=>"Selections can't be made on scalars (field 'id' returns Int but has selections [something, someFields])",
      "locations"=>[{"line"=>5, "column"=>47}]
    }
    assert_includes(errors, illegal_selection_error, "finds illegal selections on scalarss")

    selection_required_error = {
      "message"=>"Objects must have selections (field 'cheese' returns Cheese but has no selections)",
      "locations"=>[{"line"=>4, "column"=>7}]
    }
    assert_includes(errors, selection_required_error, "finds objects without selections")
  end
end
