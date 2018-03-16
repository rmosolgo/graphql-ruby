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

  describe ".from_dsl" do
    it "accepts an existing argument" do
      existing = GraphQL::Argument.define do
        name "bar"
        type GraphQL::STRING_TYPE
      end

      arg = GraphQL::Argument.from_dsl(:foo, existing)

      assert_equal "foo", arg.name
      assert_equal GraphQL::STRING_TYPE, arg.type
    end

    it "accepts a definition block after defining kwargs" do
      arg = GraphQL::Argument.from_dsl(:foo, GraphQL::STRING_TYPE) do
        description "my type is #{target.type}"
      end

      assert_equal "my type is String", arg.description
    end

    it "accepts a definition block with existing arg" do
      existing = GraphQL::Argument.define do
        name "bar"
        type GraphQL::STRING_TYPE
      end

      arg = GraphQL::Argument.from_dsl(:foo, existing) do
        description "Description for an existing field."
      end

      assert_equal "Description for an existing field.", arg.description
    end

    it "creates an argument from dsl arguments" do
      arg = GraphQL::Argument.from_dsl(
        :foo,
        GraphQL::STRING_TYPE,
        "A Description",
        default_value: "Bar"
      )

      assert_equal "foo", arg.name
      assert_equal GraphQL::STRING_TYPE, arg.type
      assert_equal "A Description", arg.description
      assert_equal "Bar", arg.default_value
    end
  end

  it "accepts custom keywords" do
    type = GraphQL::ObjectType.define do
      name "Something"
      field :something, types.String do
        argument "flagged", types.Int, metadata_flag: :flag_1
      end
    end

    arg = type.fields["something"].arguments["flagged"]
    assert_equal true, arg.metadata[:flag_1]
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

    it "can be set in the passed block" do
      argument = GraphQL::Argument.define do
        name "arg"
        as "arg_name"
      end
      assert_equal "arg_name", argument.as
    end
  end

  describe "prepare" do
    it "accepts a prepare proc and calls it to generate the prepared value" do
      prepare_proc = Proc.new { |arg, ctx| arg + ctx[:val] }
      argument = GraphQL::Argument.define(name: :plusOne, type: GraphQL::INT_TYPE, prepare: prepare_proc)
      assert_equal argument.prepare(1, {val: 1}), 2
    end

    it "returns the value itself if no prepare proc is provided" do
      argument = GraphQL::Argument.define(name: :someNumber, type: GraphQL::INT_TYPE)
      assert_equal argument.prepare(1, nil), 1
    end

    it "can be set in the passed block" do
      prepare_proc = Proc.new { |arg, ctx| arg + ctx[:val] }
      argument = GraphQL::Argument.define do
        name "arg"
        prepare prepare_proc
      end
      assert_equal argument.prepare(1, {val: 1}), 2
    end
  end
end
