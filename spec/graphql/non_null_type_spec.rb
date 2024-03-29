# frozen_string_literal: true
require "spec_helper"

describe "GraphQL::NonNullType" do
  describe "when a non-null field returns null" do
    it "nulls out the parent selection" do
      query_string = %|{ cow { name cantBeNullButIs } }|
      result = Dummy::Schema.execute(query_string)
      assert_equal({"cow" => nil }, result["data"])
      assert_equal([{"message"=>"Cannot return null for non-nullable field Cow.cantBeNullButIs"}], result["errors"])
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
      assert_equal([{"message"=>"Cannot return null for non-nullable field DeepNonNull.nonNullInt"}], result["errors"])
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
        assert_nil(err.value)
      end
    end
  end
end
