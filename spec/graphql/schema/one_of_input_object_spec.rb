# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::OneOfInputObject do
  let(:one_of_input_object) do
    Class.new(GraphQL::Schema::OneOfInputObject) do
      graphql_name "OneOfInputObject"

      member :int, Int
      member :string, String
    end
  end

  it "inherits input object behavior" do
    assert_equal(true, one_of_input_object < GraphQL::Schema::InputObject)
  end

  it "has a directive" do
    directive_classes = one_of_input_object.directives.map(&:class)
    assert_equal([GraphQL::Schema::Directive::OneOf], directive_classes)
  end

  describe ".member" do
    it "creates arguments" do
      argument_names = one_of_input_object.arguments.keys.sort
      assert_equal(['int', 'string'], argument_names)
    end

    it "rejects required arguments" do
      error = assert_raises(ArgumentError) do
        Class.new(GraphQL::Schema::OneOfInputObject) do
          graphql_name "OneOfInputObject"

          member :int, Int, required: true
          member :string, String
        end
      end

      expected_message = "Argument 'OneOfInputObject.int' must be nullable as it is part of a OneOf Type."
      assert_equal(expected_message, error.message)
    end

    it "rejects a default value" do
      error = assert_raises(ArgumentError) do
        Class.new(GraphQL::Schema::OneOfInputObject) do
          graphql_name "OneOfInputObject"

          member :int, Int, default_value: 10
          member :string, String
        end
      end

      expected_message = "Argument 'OneOfInputObject.int' cannot have a default value as it is part of a OneOf Type."
      assert_equal(expected_message, error.message)
    end
  end
end
