# frozen_string_literal: true
require 'spec_helper'

describe GraphQL::Schema::HasSingleInputArgument do
  describe ".input_object_class" do
    it "is inherited, with a default" do
      custom_input = Class.new(GraphQL::Schema::InputObject)
      mutation_base_class = Class.new(GraphQL::Schema::Mutation) do
        include GraphQL::Schema::HasSingleInputArgument
        graphql_name "Test"
        input_object_class(custom_input)
      end
      mutation_subclass = Class.new(mutation_base_class)

      assert_equal custom_input, mutation_base_class.input_object_class
      assert_equal custom_input, mutation_subclass.input_object_class
    end
  end

  describe ".input_type" do
    it "has a reference to the mutation" do
      mutation = Class.new(GraphQL::Schema::Mutation) do
        include GraphQL::Schema::HasSingleInputArgument
        graphql_name "Test"
      end
      assert_equal mutation, mutation.input_type.mutation
    end
  end

  describe "input argument" do
    it "sets a description for the input argument" do
      mutation = Class.new(GraphQL::Schema::Mutation) do
        include GraphQL::Schema::HasSingleInputArgument
        graphql_name "SomeMutation"
      end

      field = GraphQL::Schema::Field.new(name: "blah", resolver_class: mutation)
      assert_equal "Parameters for SomeMutation", field.get_argument("input").description
    end
  end
end
