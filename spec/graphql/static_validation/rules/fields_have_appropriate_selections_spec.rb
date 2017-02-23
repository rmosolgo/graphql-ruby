# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::FieldsHaveAppropriateSelections do
  include StaticValidationHelpers
  let(:query_string) {"
    query getCheese {
      okCheese: cheese(id: 1) { fatContent, similarCheese(source: YAK) { source } }
      missingFieldsCheese: cheese(id: 1)
      illegalSelectionCheese: cheese(id: 1) { id { something, ... someFields } }
    }
  "}

  it "adds errors for selections on scalars" do
    assert_equal(2, errors.length)

    illegal_selection_error = {
      "message"=>"Selections can't be made on scalars (field 'id' returns Int but has selections [something, someFields])",
      "locations"=>[{"line"=>5, "column"=>47}],
      "fields"=>["query getCheese", "illegalSelectionCheese", "id"],
    }
    assert_includes(errors, illegal_selection_error, "finds illegal selections on scalarss")

    selection_required_error = {
      "message"=>"Objects must have selections (field 'cheese' returns Cheese but has no selections)",
      "locations"=>[{"line"=>4, "column"=>7}],
      "fields"=>["query getCheese", "missingFieldsCheese"],
    }
    assert_includes(errors, selection_required_error, "finds objects without selections")
  end

  describe "anonymous operations" do
    let(:query_string) { "{ }" }
    it "requires selections" do
      assert_equal(1, errors.length)

      selections_required_error = {
        "message"=> "Objects must have selections (anonymous query returns Query but has no selections)",
        "locations"=>[{"line"=>1, "column"=>1}],
        "fields"=>["query"]
      }
      assert_includes(errors, selections_required_error)
    end
  end
end
