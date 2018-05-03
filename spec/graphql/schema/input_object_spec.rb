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

    it "inherits arguments" do
      base_class = Class.new(GraphQL::Schema::InputObject) do
        argument :arg1, String, required: true
        argument :arg2, String, required: true
      end

      subclass = Class.new(base_class) do
        argument :arg2, Integer, required: true
        argument :arg3, Integer, required: true
      end

      assert_equal 3, subclass.arguments.size
      assert_equal ["arg1", "arg2", "arg3"], subclass.arguments.keys
      assert_equal ["String!", "Int!", "Int!"], subclass.arguments.values.map { |a| a.type.to_s }
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

  describe "prepare: / as:" do
    module InputObjectPrepareTest
      class InputObj < GraphQL::Schema::InputObject
        argument :a, Integer, required: true
        argument :b, Integer, required: true, as: :b2
        argument :c, Integer, required: true, prepare: :prep
        argument :d, Integer, required: true, prepare: :prep, as: :d2

        def prep(val)
          val * context[:multiply_by]
        end
      end

      class Query < GraphQL::Schema::Object
        field :inputs, String, null: false do
          argument :input, InputObj, required: true
        end

        def inputs(input:)
          input.to_kwargs.inspect
        end
      end

      class Schema < GraphQL::Schema
        query(Query)
      end
    end

    it "calls methods on the input object" do
      query_str = <<-GRAPHQL
      { inputs(input: { a: 1, b: 2, c: 3, d: 4 }) }
      GRAPHQL

      res = InputObjectPrepareTest::Schema.execute(query_str, context: { multiply_by: 3 })
      expected_obj = { a: 1, b2: 2, c: 9, d2: 12 }.inspect
      assert_equal expected_obj, res["data"]["inputs"]
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
