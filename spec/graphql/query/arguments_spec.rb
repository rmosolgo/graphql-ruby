require "spec_helper"

describe GraphQL::Query::Arguments do
  let(:arguments) { GraphQL::Query::Arguments.new({ a: 1, b: 2, c: GraphQL::Query::Arguments.new({ d: 3, e: 4}) }) }

  it "returns keys as strings" do
    assert_equal(["a", "b", "c"], arguments.keys)
  end

  it "delegates values to values hash" do
    assert_equal([1, 2, {"d" => 3, "e" => 4}], arguments.values)
  end

  it "delegates each to values hash" do
    pairs = []
    arguments.each do |key, value|
      pairs << [key, value]
    end
    assert_equal([["a", 1], ["b", 2], ["c", {"d" => 3, "e" => 4}]], pairs)
  end

  it "returns original Ruby hash values with to_h" do
    assert_equal({ a: 1, b: 2, c: { d: 3, e: 4 } }, arguments.to_h)
  end
end
