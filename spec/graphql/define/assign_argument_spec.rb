# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Define::AssignArgument do
  it "it accepts default_value" do
    arg = define_argument(:a, GraphQL::STRING_TYPE, default_value: 'Default')

    assert_equal "Default", arg.default_value
    assert arg.default_value?
  end

  it "default_value is optional" do
    arg = define_argument(:a, GraphQL::STRING_TYPE)

    assert arg.default_value.nil?
    assert !arg.default_value?
  end

  it "default_value can be explicitly set to nil" do
    arg = define_argument(:a, GraphQL::STRING_TYPE, default_value: nil)

    assert arg.default_value.nil?
    assert arg.default_value?
  end

  it "passing unknown keyword arguments will raise" do
    err = assert_raises GraphQL::Define::NoDefinitionError do
      define_argument(:a, GraphQL::STRING_TYPE, blah: nil)
    end

    assert_equal "GraphQL::Argument can't define 'blah'", err.message

    err = assert_raises GraphQL::Define::NoDefinitionError do
      define_argument(:a, GraphQL::STRING_TYPE, blah: nil, blah2: nil)
    end

    assert_equal "GraphQL::Argument can't define 'blah'", err.message
  end

  it "accepts an existing argument" do
    existing = GraphQL::Argument.define do
      name "bar"
      type GraphQL::STRING_TYPE
    end

    arg = define_argument(:foo, existing)

    assert_equal "foo", arg.name
    assert_equal GraphQL::STRING_TYPE, arg.type
  end

  def define_argument(*args)
    type = GraphQL::ObjectType.define do
      field :a, types.String do
        argument(*args)
      end
    end

    type.fields['a'].arguments[args.first.to_s]
  end
end
