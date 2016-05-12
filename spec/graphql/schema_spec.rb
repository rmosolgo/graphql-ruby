require "spec_helper"

describe GraphQL::Schema do
  let(:schema) { DummySchema }

  after do
    schema.query_cache.clear
  end

  describe "#rescue_from" do
    let(:rescue_middleware) { schema.middleware.first }

    it "adds handlers to the rescue middleware" do
      assert_equal(1, rescue_middleware.rescue_table.length)
      # normally, you'd use a real class, not a symbol:
      schema.rescue_from(:error_class) { "my custom message" }
      assert_equal(2, rescue_middleware.rescue_table.length)
    end
  end

  describe "#subscription" do
    it "calls fields on the subscription type" do
      res = schema.execute("subscription { test }")
      assert_equal("Test", res["data"]["test"])
    end
  end

  describe "#cache(query_string)" do
    it "adds queries to the cache" do
      schema.cache("
        query getBrie { cheese(id: 1) { ... cheeseFields }}
        query getBrie2 { cheese(id: 1) { ... cheeseFields }}
        fragment cheeseFields on Cheese { flavor }
      ")
      schema.cache("
        query getBrie3 { cheese(id: 1) { flavor }}
      ")

      assert_equal 3, schema.query_cache.size
    end
  end

  describe "#execute" do
    it "executes queries from string" do
      res = schema.execute("query { cheese(id: 1) { flavor }}")
      assert_equal("Brie", res["data"]["cheese"]["flavor"])
    end

    it "executes queries from the cache" do
      schema.cache("
        query getBrie { cheese(id: 1) { ... cheeseFields }}
        query getCheese($id: Int!) { cheese(id: $id) { ... cheeseFields }}
        fragment cheeseFields on Cheese { flavor }
      ")
      res = schema.execute(operation_name: "getBrie")
      assert_equal "Brie", res["data"]["cheese"]["flavor"]

      res = schema.execute(operation_name: "getCheese", variables: {"id" => 2})
      assert_equal "Gouda", res["data"]["cheese"]["flavor"]

      res = schema.execute(operation_name: "getCheese", variables: {"id" => 3})
      assert_equal "Manchego", res["data"]["cheese"]["flavor"]
    end
  end
end
