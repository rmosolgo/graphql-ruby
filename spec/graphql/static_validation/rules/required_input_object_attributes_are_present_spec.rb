# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::RequiredInputObjectAttributesArePresent do
  include StaticValidationHelpers
  include ErrorBubblingHelpers

  let(:query_string) {%|
    query getCheese {
      stringCheese: cheese(id: "aasdlkfj") { ...cheeseFields }
      cheese(id: 1) { source @skip(if: "whatever") }
      yakSource: searchDairy(product: [{source: COW, fatContent: 1.1}]) { __typename }
      badSource: searchDairy(product: [{source: 1.1}]) { __typename }
      missingSource: searchDairy(product: [{fatContent: 1.1}]) { __typename }
      listCoerce: cheese(id: 1) { similarCheese(source: YAK) { __typename } }
      missingInputField: searchDairy(product: [{source: YAK, wacky: 1}]) { __typename }
    }

    fragment cheeseFields on Cheese {
      similarCheese(source: 4.5) { __typename }
    }
  |}
  describe "with error bubbling disabled" do
    missing_required_field_error = {
      "message"=>"Argument 'product' on Field 'missingSource' has an invalid value. Expected type '[DairyProductInput]'.",
      "locations"=>[{"line"=>7, "column"=>7}],
      "fields"=>["query getCheese", "missingSource", "product"],
    }
    missing_source_error = {"message"=>
      "Argument 'source' on InputObject 'DairyProductInput' is required. Expected type DairyAnimal!",
     "locations"=>[{"line"=>7, "column"=>44}],
     "fields"=>["query getCheese", "missingSource", "product", "source"]}
    it "finds undefined or missing-required arguments to fields and directives" do
      without_error_bubbling(schema) do
        assert_includes(errors, missing_source_error)
        refute_includes(errors, missing_required_field_error)
      end
    end
    it 'works with error bubbling enabled' do
      with_error_bubbling(schema) do
        assert_includes(errors, missing_required_field_error)
        assert_includes(errors, missing_source_error)
      end
    end
  end
end
