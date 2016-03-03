require "spec_helper"

describe GraphQL::ListType do
  let(:float_list) { GraphQL::ListType.new(of_type: GraphQL::FLOAT_TYPE) }

  it "coerces elements in the list" do
    assert_equal([1.0, 2.0, 3.0].inspect, float_list.coerce_input([1, 2, 3]).inspect)
  end

  describe "validate_input with bad input" do
    let(:bad_num) { "bad_num" }
    let(:result) { float_list.validate_input([bad_num, 2.0, 3.0]) }

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
      expected = GraphQL::FLOAT_TYPE.validate_input(bad_num).problems[0]["explanation"]
      actual = result.problems[0]["explanation"]
      assert_equal(actual, expected)
    end
  end
end
