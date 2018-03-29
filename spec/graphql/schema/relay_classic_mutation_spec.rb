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
end
