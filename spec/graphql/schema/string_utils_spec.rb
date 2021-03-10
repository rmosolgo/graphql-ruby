# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::StringUtils do
  describe ".setup with argument" do
    it "turns underscore to lower camelcase" do
      implementation = Module.new do
        def camelize(string)
          return "withModule" if string == "with_module"
          super
        end
      end

      GraphQL::Schema::StringUtils.setup(implementation)

      assert_equal "withModule", GraphQL::Schema::StringUtils.camelize("with_module")
    end
  end

  describe ".setup with block" do
    it "turns underscore to lower camelcase" do

      GraphQL::Schema::StringUtils.setup do
        def camelize(string)
          return "withBlock" if string == "with_block"
          super
        end
      end

      assert_equal "withBlock", GraphQL::Schema::StringUtils.camelize("with_block")
    end
  end

  describe ".camelize" do
    it "turns underscore to lower camelcase" do
      assert_equal "fooBar", GraphQL::Schema::StringUtils.camelize("foo_bar")
    end
  end

  describe ".underscore" do
    it "turns camelcase to underscore" do
      assert_equal "foo_bar", GraphQL::Schema::StringUtils.underscore("fooBar")
    end
  end

  describe ".constantize" do
    it "turns string into constant" do
      assert_equal GraphQL::Schema::StringUtils, GraphQL::Schema::StringUtils.constantize("GraphQL::Schema::StringUtils")
    end
  end
end
