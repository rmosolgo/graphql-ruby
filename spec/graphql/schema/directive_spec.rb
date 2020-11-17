# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Directive do
  class MultiWord < GraphQL::Schema::Directive
  end

  it "uses a downcased class name" do
    assert_equal "multiWord", MultiWord.graphql_name
  end

  module DirectiveTest
    class Secret < GraphQL::Schema::Directive
      argument :top_secret, Boolean, required: true
      locations(FIELD_DEFINITION, ARGUMENT_DEFINITION)
    end

    class Thing < GraphQL::Schema::Object
      field :name, String, null: false do
        directive Secret, { top_secret: true }
        argument :nickname, Boolean, required: false do
          directive Secret, { top_secret: false }
        end
      end
    end
  end

  it "can be added to schema definitions" do
    field = DirectiveTest::Thing.fields.values.first

    assert_equal [DirectiveTest::Secret], field.directives.map(&:class)
    assert_equal [field], field.directives.map(&:owner)
    assert_equal [true], field.directives.map{ |d| d.arguments[:top_secret] }

    argument = field.arguments.values.first
    assert_equal [DirectiveTest::Secret], argument.directives.map(&:class)
    assert_equal [argument], argument.directives.map(&:owner)
    assert_equal [false], argument.directives.map{ |d| d.arguments[:top_secret] }
  end

  it "raises an error when added to the wrong thing" do
    err = assert_raises ArgumentError do
      Class.new(GraphQL::Schema::Object) do
        graphql_name "Stuff"
        directive DirectiveTest::Secret
      end
    end

    expected_message = "Directive `@secret` can't be attached to Stuff because OBJECT isn't included in its locations (FIELD_DEFINITION, ARGUMENT_DEFINITION).

Use `locations(OBJECT)` to update this directive's definition, or remove it from Stuff.
"

    assert_equal expected_message, err.message
  end

  it "raises an error when arguments are missing or mistyped"
  it "appears in schema dumps"
  it "is loaded from schema dumps"
end
