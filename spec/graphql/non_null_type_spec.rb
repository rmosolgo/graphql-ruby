# frozen_string_literal: true
require "spec_helper"

describe "GraphQL::NonNullType" do
  describe "when the interpreter receives a nested list containing an invalid null" do
    class NestedListSchema < GraphQL::Schema
      class Query < GraphQL::Schema::Object
        field :nested, [[Int]], hash_key: :nested
        field :required_nested, [[Int]], null: false, hash_key: :nested
        field :nullable_lists, [[Int], null: true], hash_key: :nested
        field :deeply_nested, [[[Int]]], hash_key: :nested
      end

      query(Query)
      default_execution_next(false)

      def self.type_error(error, context)
        context[:type_error] = error
        super
      end
    end

    it "nulls the field and reports the item path" do
      result = NestedListSchema.execute("{ nested }", root_value: { nested: [[1], [nil], [3]] })

      assert_equal({ "nested" => nil }, result["data"])
      assert_equal [["nested", 1, 0]], result["errors"].map { |error| error["path"] }
      error = result.context[:type_error]
      assert_instance_of NestedListSchema::Query::InvalidNullError, error
      assert_equal NestedListSchema::Query, error.parent_type
      assert_equal NestedListSchema::Query.fields["nested"], error.field
      assert error.is_from_array
    end

    it "propagates null through a non-null field" do
      result = NestedListSchema.execute("{ requiredNested }", root_value: { nested: [[1], [nil], [3]] })

      assert_nil result["data"]
      assert_equal [["requiredNested", 1, 0]], result["errors"].map { |error| error["path"] }
    end

    it "stops propagation at a nullable inner list" do
      result = NestedListSchema.execute("{ nullableLists }", root_value: { nested: [[1], [nil], [3]] })

      assert_equal({ "nullableLists" => [[1], nil, [3]] }, result["data"])
      assert_equal [["nullableLists", 1, 0]], result["errors"].map { |error| error["path"] }
    end

    it "reports nulls in more deeply nested lists" do
      result = NestedListSchema.execute("{ deeplyNested }", root_value: { nested: [[[1]], [[nil]], [[3]]] })

      assert_equal({ "deeplyNested" => nil }, result["data"])
      assert_equal [["deeplyNested", 1, 0, 0]], result["errors"].map { |error| error["path"] }
    end
  end

  describe "when a non-null field returns null" do
    it "nulls out the parent selection" do
      query_string = %|{ cow { name cantBeNullButIs } }|
      result = Dummy::Schema.execute(query_string)
      assert_equal({"cow" => nil }, result["data"])
      assert_equal([{
        "message" => "Cannot return null for non-nullable field Cow.cantBeNullButIs",
        "path" => ["cow", "cantBeNullButIs"],
        "locations" => [{"line" => 1, "column" => 14}],
      }], result["errors"])
    end

    it "propagates the null up to the next nullable field" do
      query_string = %|
      {
        nn1: deepNonNull {
          nni1: nonNullInt(returning: 1)
          nn2: deepNonNull {
            nni2: nonNullInt(returning: 2)
            nn3: deepNonNull {
              nni3: nonNullInt
            }
          }
        }
      }
      |
      result = Dummy::Schema.execute(query_string)
      assert_nil(result["data"])
      assert_equal([{
        "message" => "Cannot return null for non-nullable field DeepNonNull.nonNullInt",
        "path" => ["nn1", "nn2", "nn3", "nni3"],
        "locations" => [{"line" => 8, "column" => 15}],
      }], result["errors"])
    end

    describe "when type_error is configured to raise an error" do
      it "crashes query execution" do
        raise_schema = Class.new(Dummy::Schema) {
          def self.type_error(type_err, ctx)
            raise type_err
          end
        }
        query_string = %|{ cow { name cantBeNullButIs } }|
        err = assert_raises(GraphQL::InvalidNullError) { raise_schema.execute(query_string) }
        assert_equal("Cannot return null for non-nullable field Cow.cantBeNullButIs", err.message)
        assert_equal("Cow", err.parent_type.graphql_name)
        assert_equal("cantBeNullButIs", err.field.name)
      end
    end
  end
end
