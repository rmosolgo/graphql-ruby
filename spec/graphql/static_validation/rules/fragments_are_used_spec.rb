# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::FragmentsAreUsed do
  include StaticValidationHelpers
  let(:query_string) {"
    query getCheese {
      name
      ...cheeseFields
      ...undefinedFields
    }
    fragment cheeseFields on Cheese { fatContent }
    fragment unusedFields on Cheese { is, not, used }
  "}

  it "adds errors for unused fragment definitions" do
    assert_includes(errors, {
      "message"=>"Fragment unusedFields was defined, but not used",
      "locations"=>[{"line"=>8, "column"=>5}],
      "path"=>["fragment unusedFields"],
      "extensions"=>{"code"=>"useAndDefineFragment", "fragmentName"=>"unusedFields"}
    })
  end

  it "adds errors for undefined fragment spreads" do
    assert_includes(errors, {
      "message"=>"Fragment undefinedFields was used, but not defined",
      "locations"=>[{"line"=>5, "column"=>7}],
      "path"=>["query getCheese", "... undefinedFields"],
      "extensions"=>{"code"=>"useAndDefineFragment", "fragmentName"=>"undefinedFields"}
    })
  end

  describe "queries that are comments" do
    let(:query_string) {%|
      # I am a comment.
    |}
    let(:result) { Dummy::Schema.execute(query_string) }
    it "handles them gracefully" do
      assert_equal({}, result)
    end
  end

  describe "invalid unused fragments" do
    let(:query_string) {"
      query getCheese {
        name
      }
      fragment Invalid on DoesNotExist { fatContent }
    "}

    it "handles them gracefully" do
      assert_includes(errors, {
        "message"=>"No such type DoesNotExist, so it can't be a fragment condition",
        "locations"=>[{"line"=>5, "column"=>7}],
        "path"=>["fragment Invalid"],
        "extensions"=>{"code"=>"undefinedType", "typeName"=>"DoesNotExist"}
      })
    end
  end
end
