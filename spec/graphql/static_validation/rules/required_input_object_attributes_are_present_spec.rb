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
      missingNestedRequiredInputObjectAttribute: searchDairy(product: [{fatContent: 1.2, order_by: {}}]) { __typename }
      errorAtIndexOne: searchDairy(product: [{source: COW, fatContent: 1.0}, {fatContent: 1.2, order_by: {}}]) { __typename }
      listCoerce: cheese(id: 1) { similarCheese(source: YAK) { __typename } }
      missingInputField: searchDairy(product: [{source: YAK, wacky: 1}]) { __typename }
    }

    fragment cheeseFields on Cheese {
      similarCheese(source: 4.5) { __typename }
    }
  |}
  describe "with error bubbling disabled" do
    missing_required_field_error = {
      "message"=>"Argument 'product' on Field 'missingSource' has an invalid value ([{fatContent: 1.1}]). Expected type '[DairyProductInput]'.",
      "locations"=>[{"line"=>7, "column"=>7}],
      "path"=>["query getCheese", "missingSource", "product"],
      "extensions"=>{
        "code"=>"argumentLiteralsIncompatible",
        "typeName"=>"Field",
        "argumentName"=>"product",
      },
    }
    missing_source_error = {
      "message"=>"Argument 'source' on InputObject 'DairyProductInput' is required. Expected type DairyAnimal!",
      "locations"=>[{"line"=>7, "column"=>44}],
      "path"=>["query getCheese", "missingSource", "product", 0, "source"],
      "extensions"=>{
        "code"=>"missingRequiredInputObjectAttribute",
        "argumentName"=>"source",
        "argumentType"=>"DairyAnimal!",
        "inputObjectType"=>"DairyProductInput"
      }
    }
    missing_order_by_direction_error = {
      "message"=>"Argument 'direction' on InputObject 'ResourceOrderType' is required. Expected type String!",
      "locations"=>[{"line"=>8, "column"=>100}],
      "path"=>["query getCheese", "missingNestedRequiredInputObjectAttribute", "product", 0, "order_by", "direction"],
      "extensions"=>{
        "code"=>"missingRequiredInputObjectAttribute",
        "argumentName"=>"direction",
        "argumentType"=>"String!",
        "inputObjectType"=>"ResourceOrderType"
      }
    }
    missing_order_by_direction_index_one_error = {
      "message"=>"Argument 'direction' on InputObject 'ResourceOrderType' is required. Expected type String!",
      "locations"=>[{"line"=>9, "column"=>106}],
      "path"=>["query getCheese", "errorAtIndexOne", "product", 1, "order_by", "direction"],
      "extensions"=>{
        "code"=>"missingRequiredInputObjectAttribute",
        "argumentName"=>"direction",
        "argumentType"=>"String!",
        "inputObjectType"=>"ResourceOrderType"
      }
    }
    it "finds undefined or missing-required arguments to fields and directives" do
      without_error_bubbling(schema) do
        assert_includes(errors, missing_source_error)
        assert_includes(errors, missing_order_by_direction_error)
        assert_includes(errors, missing_order_by_direction_index_one_error)
        refute_includes(errors, missing_required_field_error)
      end
    end
    it 'works with error bubbling enabled' do
      with_error_bubbling(schema) do
        assert_includes(errors, missing_required_field_error)
        assert_includes(errors, missing_source_error)
        assert_includes(errors, missing_order_by_direction_error)
        assert_includes(errors, missing_order_by_direction_index_one_error)
      end
    end
  end
end
