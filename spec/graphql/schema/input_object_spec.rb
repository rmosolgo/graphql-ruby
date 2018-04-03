# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::InputObject do
  let(:input_object) { Jazz::EnsembleInput }
  describe "type info" do
    it "has it" do
      assert_equal "EnsembleInput", input_object.graphql_name
      assert_equal nil, input_object.description
      assert_equal 1, input_object.arguments.size
    end

    it "is the #owner of its arguments" do
      argument = input_object.arguments["name"]
      assert_equal input_object, argument.owner
    end
  end

  describe ".to_graphql" do
    it "assigns itself as the arguments_class" do
      assert_equal input_object, input_object.to_graphql.arguments_class
    end

    it "accepts description: kwarg" do
      input_obj_class = Jazz::InspectableInput
      input_obj_type = input_obj_class.to_graphql
      assert_equal "Test description kwarg", input_obj_type.arguments["stringValue"].description
    end
  end

  describe "in queries" do
    it "is passed to the field method" do
      query_str = <<-GRAPHQL
      {
        inspectInput(input: {
          stringValue: "ABC",
          legacyInput: { intValue: 4 },
          nestedInput: { stringValue: "xyz"}
        })
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str, context: { message: "hi" })
      expected_info = [
        "Jazz::InspectableInput",
        "hi, ABC, 4, (hi, xyz, -, (-))",
        "ABC",
        "ABC",
        "true",
        "ABC",
      ]
      assert_equal expected_info, res["data"]["inspectInput"]
    end
  end
end
