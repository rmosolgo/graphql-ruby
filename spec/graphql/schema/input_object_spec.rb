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
      assert_equal ["String!", "Int!", "Int!"], subclass.arguments.values.map { |a| a.type.to_type_signature }
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
        argument :e, Integer, required: true, prepare: ->(val, ctx) { val * ctx[:multiply_by] * 2 }, as: :e2

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
      { inputs(input: { a: 1, b: 2, c: 3, d: 4, e: 5 }) }
      GRAPHQL

      res = InputObjectPrepareTest::Schema.execute(query_str, context: { multiply_by: 3 })
      expected_obj = { a: 1, b2: 2, c: 9, d2: 12, e2: 30 }.inspect
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

  describe "#to_h" do
    module InputObjectToHTest
      class TestInput1 < GraphQL::Schema::InputObject
        graphql_name "TestInput1"
        argument :d, Int, required: true
        argument :e, Int, required: true
      end

      class TestInput2 < GraphQL::Schema::InputObject
        graphql_name "TestInput2"
        argument :a, Int, required: true
        argument :b, Int, required: true
        argument :c, TestInput1, as: :inputObject, required: true
      end

      TestInput1.to_graphql
      TestInput2.to_graphql
    end

    it "returns a symbolized, aliased, ruby keyword style hash" do
      arg_values = {a: 1, b: 2, c: { d: 3, e: 4 }}

      input_object = InputObjectToHTest::TestInput2.new(
        arg_values,
        context: nil,
        defaults_used: Set.new
      )

      assert_equal({ a: 1, b: 2, input_object: { d: 3, e: 4 } }, input_object.to_h)
    end
  end
end
