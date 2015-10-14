require "spec_helper"

describe GraphQL::Query::Inputs do
  let(:child_inputs) { GraphQL::Query::Inputs.new({"a" => 1, "b" => false }, parent: parent_inputs)}
  let(:parent_inputs) { GraphQL::Query::Inputs.new({"b" => 100, "c" => 100}, parent: {})}
  describe "key lookup" do
    it "stringifies inputs" do
      assert_equal(1, child_inputs["a"])
      assert_equal(1, child_inputs[:a])
    end
    it "prefers the value from the child" do
      assert_equal(false, child_inputs["b"])
    end
    it "falls back to a value from the parent for missing keys" do
      assert_equal(100, child_inputs["c"])
    end
  end
end
