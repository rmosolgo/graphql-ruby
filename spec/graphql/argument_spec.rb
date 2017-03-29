# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Argument do
  it "is validated at schema build-time" do
    query_type = GraphQL::ObjectType.define do
      name "Query"
      field :invalid, types.Boolean do
        argument :invalid, types.Float, default_value: ["123"]
      end
    end

    err = assert_raises(GraphQL::Schema::InvalidTypeError) {
      schema = GraphQL::Schema.define(query: query_type)
      schema.types
    }

    expected_error = %|Query is invalid: field "invalid" argument "invalid" default value ["123"] is not valid for type Float|
    assert_includes err.message, expected_error
  end

  it "accepts proc type" do
    argument = GraphQL::Argument.define(name: :favoriteFood, type: -> { GraphQL::STRING_TYPE })
    assert_equal GraphQL::STRING_TYPE, argument.type
  end

  it "accepts a default_value" do
    argument = GraphQL::Argument.define(name: :favoriteFood, type: GraphQL::STRING_TYPE, default_value: 'Default')
    assert_equal 'Default', argument.default_value
    assert argument.default_value?
  end

  it "accepts a default_value of nil" do
    argument = GraphQL::Argument.define(name: :favoriteFood, type: GraphQL::STRING_TYPE, default_value: nil)
    assert argument.default_value.nil?
    assert argument.default_value?
  end

  it "default_value is optional" do
    argument = GraphQL::Argument.define(name: :favoriteFood, type: GraphQL::STRING_TYPE)
    assert argument.default_value.nil?
    assert !argument.default_value?
  end

  describe "#as, #exposed_as" do
    it "accepts a `as` property to define the arg name at resolve time" do
      argument = GraphQL::Argument.define(name: :favoriteFood, type: GraphQL::STRING_TYPE, as: :favFood)
      assert_equal argument.as, :favFood
    end

    it "uses `name` or `as` for `expose_as`" do
      arg_1 = GraphQL::Argument.define(name: :favoriteFood, type: GraphQL::STRING_TYPE, as: :favFood)
      assert_equal arg_1.expose_as, "favFood"
      arg_2 = GraphQL::Argument.define(name: :favoriteFood, type: GraphQL::STRING_TYPE)
      assert_equal arg_2.expose_as, "favoriteFood"
      arg_3 = arg_2.redefine { as :ff }
      assert_equal arg_3.expose_as, "ff"
    end
  end

  describe "prepare" do
    it "accepts a prepare proc and calls it to generate the prepared value" do
      prepare_proc = Proc.new { |arg| arg + 1 }
      argument = GraphQL::Argument.define(name: :plusOne, type: GraphQL::INT_TYPE, prepare: prepare_proc)
      assert_equal argument.prepare(1), 2
    end

    it "returns the value itself if no prepare proc is provided" do
      argument = GraphQL::Argument.define(name: :someNumber, type: GraphQL::INT_TYPE)
      assert_equal argument.prepare(1), 1
    end
  end
end
