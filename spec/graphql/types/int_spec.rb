# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Types::Int do
  describe "coerce_input" do
    it "accepts ints within the bounds" do
      assert_equal(-(2**31), GraphQL::Types::Int.coerce_isolated_input(-(2**31)))
      assert_equal 1, GraphQL::Types::Int.coerce_isolated_input(1)
      assert_equal (2**31)-1, GraphQL::Types::Int.coerce_isolated_input((2**31)-1)
    end

    it "rejects other types and ints outside the bounds" do
      assert_nil GraphQL::Types::Int.coerce_isolated_input("55")
      assert_nil GraphQL::Types::Int.coerce_isolated_input(true)
      assert_nil GraphQL::Types::Int.coerce_isolated_input(6.1)

      assert_raises(GraphQL::CoercionError) do
        GraphQL::Types::Int.coerce_isolated_input(2**31)
      end

      assert_raises(GraphQL::CoercionError) do
        GraphQL::Types::Int.coerce_isolated_input(-(2**31 + 1))
      end
    end

    describe "handling boundaries" do
      let(:context) { GraphQL::Query.new(Dummy::Schema, "{ __typename }").context }

      it "accepts result values in bounds" do
        assert_equal 0, GraphQL::Types::Int.coerce_result(0, context)
        assert_equal (2**31) - 1, GraphQL::Types::Int.coerce_result((2**31) - 1, context)
        assert_equal(-(2**31), GraphQL::Types::Int.coerce_result(-(2**31), context))
      end

      it "raises on values out of bounds" do
        err_ctx = GraphQL::Query.new(Dummy::Schema, "{ __typename }").context
        assert_raises(GraphQL::CoercionError) { GraphQL::Types::Int.coerce_result(2**31, err_ctx) }
        err = assert_raises(GraphQL::CoercionError) { GraphQL::Types::Int.coerce_result(-(2**31 + 1), err_ctx) }
        assert_equal "Int cannot represent non 32-bit signed integer value: -2147483649", err.message

        err = assert_raises GraphQL::CoercionError do
          Dummy::Schema.execute("{ hugeInteger }")
        end
        assert_equal "Int cannot represent non 32-bit signed integer value: 2147483648", err.message
      end
    end
  end
end
