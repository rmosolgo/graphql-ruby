# frozen_string_literal: true
require "spec_helper"

describe GraphQL::ListType do
  let(:float_list) { GraphQL::ListType.new(of_type: GraphQL::FLOAT_TYPE) }

  it "coerces elements in the list" do
    assert_equal([1.0, 2.0, 3.0].inspect, float_list.coerce_isolated_input([1, 2, 3]).inspect)
  end

  it "converts items that are not lists into lists" do
    assert_equal([1.0].inspect, float_list.coerce_isolated_input(1.0).inspect)
  end

  describe "validate_input with bad input" do
    let(:bad_num) { "bad_num" }
    let(:result) { float_list.validate_isolated_input([bad_num, 2.0, 3.0]) }

    it "returns an invalid result" do
      assert(!result.valid?)
    end

    it "has one problem" do
      assert_equal(result.problems.length, 1)
    end

    it "has path [0]" do
      assert_equal(result.problems[0]["path"], [0])
    end

    it "has the correct explanation" do
      expected = GraphQL::FLOAT_TYPE.validate_isolated_input(bad_num).problems[0]["explanation"]
      actual = result.problems[0]["explanation"]
      assert_equal(actual, expected)
    end
  end

  describe "list of input objects" do
    let(:input_object) do
      input_object = GraphQL::InputObjectType.define do
        name "SomeInputObjectType"
        argument :float, !types.Float
      end

      GraphQL::Query::Arguments.construct_arguments_class(input_object)

      input_object
    end

    let(:input_object_list) { input_object.to_list_type }

    it "converts hashes into lists of hashes" do
      hash = { 'float' => 1.0 }
      assert_equal([hash].inspect, input_object_list.coerce_isolated_input(hash).map(&:to_h).inspect)
    end
  end
end
