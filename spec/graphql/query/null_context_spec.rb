# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Query::NullContext do
  describe "#[]" do
    it "returns nil" do
      assert_nil(GraphQL::Query::NullContext[:foo])
    end
  end

  describe "#fetch" do
    it "returns the default value argument" do
      assert_equal(:default, GraphQL::Query::NullContext.fetch(:foo, :default))
    end

    it "returns the block result" do
      assert_equal(:default, GraphQL::Query::NullContext.fetch(:foo) { :default })
    end

    it "raises a KeyError when not passed a default value or a block" do
      assert_raises(KeyError) { GraphQL::Query::NullContext.fetch(:foo) }
    end
  end

  describe "#key?" do
    it "returns false" do
      assert(!GraphQL::Query::NullContext.key?(:foo))
    end
  end

  describe "#dig?" do
    it "returns nil" do
      assert_nil(GraphQL::Query::NullContext.dig(:foo, :bar, :baz))
    end
  end
end
