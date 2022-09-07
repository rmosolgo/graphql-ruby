# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Directive::OneOf do
  let(:schema) do
    this = self
    output_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "OneOfOutput"

      field :string, GraphQL::Types::String
      field :int, GraphQL::Types::Int
    end

    query_type = Class.new(GraphQL::Schema::Object) do
        graphql_name "Query"

        field :one_of_field, output_type, null: false do
          argument :one_of_arg, this.one_of_input_object
        end

        def one_of_field(one_of_arg:)
          one_of_arg
        end
      end

    Class.new(GraphQL::Schema) do
      query(query_type)
    end
  end

  let(:one_of_input_object) do
    Class.new(GraphQL::Schema::InputObject) do
      graphql_name "OneOfInputObject"
      directive GraphQL::Schema::Directive::OneOf

      argument :int, GraphQL::Types::Int
      argument :string, GraphQL::Types::String
    end
  end

  describe "defining oneOf input objects" do
    describe "with a non-null argument" do
      let(:one_of_input_object) do
        Class.new(GraphQL::Schema::InputObject) do
          graphql_name "OneOfInputObject"
          directive GraphQL::Schema::Directive::OneOf

          argument :int, GraphQL::Types::Int, required: true # rubocop:disable GraphQL/DefaultRequiredTrue
          argument :string, GraphQL::Types::String
        end
      end

      it "raises an error" do
        error = assert_raises(ArgumentError) { schema }
        expected_message = "Argument 'OneOfInputObject.int' must be nullable because it is part of a OneOf type, add `required: false`."
        assert_equal(expected_message, error.message)
      end
    end

    describe "when an argument has a default" do
      let(:one_of_input_object) do
        Class.new(GraphQL::Schema::InputObject) do
          graphql_name "OneOfInputObject"
          directive GraphQL::Schema::Directive::OneOf

          argument :int, GraphQL::Types::Int, default_value: 1, required: false
          argument :string, GraphQL::Types::String, required: false
        end
      end

      it "raises an error" do
        error = assert_raises(ArgumentError) { schema }
        expected_message = "Argument 'OneOfInputObject.int' cannot have a default value because it is part of a OneOf type, remove `default_value: ...`."
        assert_equal(expected_message, error.message)
      end
    end
  end
end
