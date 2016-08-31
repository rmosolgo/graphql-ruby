require "spec_helper"

describe GraphQL::ID_TYPE do
  let(:result) { DairySchema.execute(query_string)}

  describe "coercion for int inputs" do
    let(:query_string) { %|query getMilk { cow: milk(id: 1) { id } }| }

    it "coerces IDs from ints and serializes as strings" do
      expected = {"data" => {"cow" => {"id" => "1"}}}
      assert_equal(expected, result)
    end
  end

  describe "coercion for string inputs" do
    let(:query_string) { %|query getMilk { cow: milk(id: "1") { id } }| }

    it "coerces IDs from strings and serializes as strings" do
      expected = {"data" => {"cow" => {"id" => "1"}}}
      assert_equal(expected, result)
    end
  end

  describe "coercion for other types" do
    let(:query_string) { %|query getMilk { cow: milk(id: 1.0) { id } }| }

    it "doesn't allow other types" do
      assert_equal nil, result["data"]
      assert_equal 1, result["errors"].length
    end
  end
end
