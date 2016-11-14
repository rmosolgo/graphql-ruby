require "spec_helper"

describe GraphQL::NonNullType do
  describe "when a non-null field returns null" do
    it "nulls out the parent selection" do
      query_string = %|{ cow { name cantBeNullButIs } }|
      result = DummySchema.execute(query_string)
      assert_equal({"cow" => nil }, result["data"])
      assert_equal([{
        "message"=>"Cannot return null for non-nullable field Cow.cantBeNullButIs",
        "locations"=>[{"line"=>1, "column"=>14}],
        "path"=>["cow", "cantBeNullButIs"],
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
      result = DummySchema.execute(query_string)
      assert_equal(nil, result["data"])
      assert_equal([{
        "message"=>"Cannot return null for non-nullable field DeepNonNull.nonNullInt",
        "locations"=>[{"line"=>8, "column"=>15}],
        "path"=>["nn1", "nn2", "nn3", "nni3"],
      }], result["errors"])
    end
  end
end
