require "spec_helper"

describe GraphQL::QueryCache do
  let(:query_cache) { GraphQL::QueryCache.new(DummySchema) }

  describe "#add" do
    it "stores operations" do
      query_cache.add("
        query getCheeseOne { cheese(id: 1) { flavor } }
        query getCheeseTwo { cheese(id: 2) { flavor } }
      ")
      assert_equal 2, query_cache.size
    end

    it "raises on a duplicate operation name" do
      query_cache.add("
        query getCheeseOne { cheese(id: 1) { flavor } }
        query getCheeseTwo { cheese(id: 2) { flavor } }
      ")

      assert_raises(GraphQL::QueryCache::DuplicateOperationNameError) {
        query_cache.add("query getCheeseOne { cheese(id: 111) { flavor } }")
      }
    end

    it "raises on an invalid query" do
      query_cache.add("query getCheeseOne { cheese(id: 1) { flavor } }")

      err = assert_raises(GraphQL::QueryCache::InvalidQueryError) {
        query_cache.add("query getCheeseTwo { cheese(id: 2) { flavorxx } }")
      }

      assert_includes(err.message, "1:22")
      assert_includes(err.message, "flavorxx")
    end
  end

  describe "#execute" do
    before do
      query_cache.add("
        query getCheeseById($id: Int!) { cheese(id: $id) { flavor } }
        query getCheeseTwo { cheese(id: 2) { flavor } }
      ")
    end

    it "runs the given operation" do
      result = query_cache.execute("getCheeseById", variables: {"id" => 1})
      assert_equal "Brie", result["data"]["cheese"]["flavor"]
    end

    it "raises on missing operation name" do
      assert_raises(GraphQL::QueryCache::OperationMissingError) {
        query_cache.execute("getNonsense")
      }
    end
  end
end
