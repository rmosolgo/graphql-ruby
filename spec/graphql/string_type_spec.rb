require "spec_helper"

describe GraphQL::STRING_TYPE do
  describe "coerce_input" do
    it "accepts strings" do
      assert_equal "str", GraphQL::STRING_TYPE.coerce_input("str")
    end

    it "doesn't accept other types" do
      assert_equal nil, GraphQL::STRING_TYPE.coerce_input(100)
      assert_equal nil, GraphQL::STRING_TYPE.coerce_input(true)
      assert_equal nil, GraphQL::STRING_TYPE.coerce_input(0.999)
    end
  end
end
