require "spec_helper"

describe GraphQL::NonNullType do
  describe "when a non-null field returns null" do
    it "nulls out the parent selection" do
      query_string = %|{ cow { name cantBeNullButIs } }|
      err = assert_raises(GraphQL::InvalidNullError) do
        DummySchema.execute(query_string)
      end
      assert_equal "Cannot return null for non-nullable field Cow.cantBeNullButIs", err.message
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
      err = assert_raises(GraphQL::InvalidNullError) do
        DummySchema.execute(query_string)
      end
      assert_equal "Cannot return null for non-nullable field DeepNonNull.nonNullInt", err.message
    end
  end
end
