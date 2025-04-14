# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Types::Float do
  let(:enum) { GraphQL::Language::Nodes::Enum.new(name: 'MILK') }

  describe "coerce_input" do
    it "accepts ints and floats" do
      assert_equal 1.0, GraphQL::Types::Float.coerce_isolated_input(1)
      assert_equal 6.1, GraphQL::Types::Float.coerce_isolated_input(6.1)
    end

    it "rejects other types" do
      assert_raises(GraphQL::CoercionError) do
        GraphQL::Types::Float.coerce_isolated_input("55")
      end

      assert_raises(GraphQL::CoercionError) do
        GraphQL::Types::Float.coerce_isolated_input(true)
      end

      assert_raises(GraphQL::CoercionError) do
        GraphQL::Types::Float.coerce_isolated_input(enum)
      end
    end
  end

  describe "coerce_result" do
    it "coercess ints and floats" do
      err_ctx = GraphQL::Query.new(Dummy::Schema, "{ __typename }").context

      assert_equal 1.0, GraphQL::Types::Float.coerce_result(1, err_ctx)
      assert_equal 1.0, GraphQL::Types::Float.coerce_result("1", err_ctx)
      assert_equal 1.0, GraphQL::Types::Float.coerce_result("1.0", err_ctx)
      assert_equal 6.1, GraphQL::Types::Float.coerce_result(6.1, err_ctx)
    end

    it "rejects other types" do
      err_ctx = GraphQL::Query.new(Dummy::Schema, "{ __typename }").context

      assert_raises(GraphQL::CoercionError) do
        GraphQL::Types::Float.coerce_result("foo", err_ctx)
      end

      assert_raises(GraphQL::CoercionError) do
        GraphQL::Types::Float.coerce_result(1.0 / 0, err_ctx)
      end
    end
  end
end
