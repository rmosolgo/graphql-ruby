# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::RelayClassicMutation do
  describe ".input_object_class" do
    it "is inherited, with a default" do
      custom_input = Class.new(GraphQL::Schema::InputObject)
      mutation_base_class = Class.new(GraphQL::Schema::RelayClassicMutation) do
        input_object_class(custom_input)
      end
      mutation_subclass = Class.new(mutation_base_class)

      assert_equal GraphQL::Schema::InputObject, GraphQL::Schema::RelayClassicMutation.input_object_class
      assert_equal custom_input, mutation_base_class.input_object_class
      assert_equal custom_input, mutation_subclass.input_object_class
    end
  end

  describe ".input_type" do
    it "has a reference to the mutation" do
      mutation = Class.new(GraphQL::Schema::RelayClassicMutation) do
        graphql_name "Test"
      end
      assert_equal mutation, mutation.input_type.mutation
      assert_equal mutation, mutation.input_type.graphql_definition.mutation
    end
  end

  describe ".null" do
    it "is inherited as true" do
      mutation = Class.new(GraphQL::Schema::RelayClassicMutation) do
        graphql_name "Test"
      end

      assert mutation.null
    end
  end

  describe "execution" do
    it "works with no arguments" do
      res = Jazz::Schema.execute <<-GRAPHQL
      mutation {
        addSitar(input: {}) {
          instrument {
            name
          }
        }
      }
      GRAPHQL

      assert_equal "Sitar", res["data"]["addSitar"]["instrument"]["name"]
    end
  end
end
