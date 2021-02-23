# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::Typecast do
  describe ".subtype?" do
    def subtype?(*args)
      GraphQL::Execution::Typecast.subtype?(*args)
    end

    it "counts the same type as a subtype" do
      assert subtype?(Dummy::Milk.graphql_definition, Dummy::Milk.graphql_definition)
      assert !subtype?(Dummy::Milk.graphql_definition, Dummy::Cheese.graphql_definition)
      assert subtype?(Dummy::Milk.graphql_definition.to_list_type.to_non_null_type, Dummy::Milk.graphql_definition.to_list_type.to_non_null_type)
    end

    it "counts member types as subtypes" do
      assert subtype?(Dummy::Edible.graphql_definition, Dummy::Cheese.graphql_definition)
      assert subtype?(Dummy::Edible.graphql_definition, Dummy::Milk.graphql_definition)
      assert subtype?(Dummy::DairyProduct.graphql_definition, Dummy::Milk.graphql_definition)
      assert subtype?(Dummy::DairyProduct.graphql_definition, Dummy::Cheese.graphql_definition)

      assert !subtype?(Dummy::DairyAppQuery.graphql_definition, Dummy::DairyProduct.graphql_definition)
      assert !subtype?(Dummy::Cheese.graphql_definition, Dummy::DairyProduct.graphql_definition)
      assert !subtype?(Dummy::Edible.graphql_definition, Dummy::DairyProduct.graphql_definition)
      assert !subtype?(Dummy::Edible.graphql_definition, GraphQL::DEPRECATED_STRING_TYPE)
      assert !subtype?(Dummy::Edible.graphql_definition, Dummy::DairyProductInput.graphql_definition)
    end

    it "counts lists as subtypes if their inner types are subtypes" do
      assert subtype?(Dummy::Edible.graphql_definition.to_list_type, Dummy::Milk.graphql_definition.to_list_type)
      assert subtype?(Dummy::DairyProduct.graphql_definition.to_list_type, Dummy::Milk.graphql_definition.to_list_type)
      assert !subtype?(Dummy::Cheese.graphql_definition.to_list_type, Dummy::DairyProduct.graphql_definition.to_list_type)
      assert !subtype?(Dummy::Edible.graphql_definition.to_list_type, Dummy::DairyProduct.graphql_definition.to_list_type)
      assert !subtype?(Dummy::Edible.graphql_definition.to_list_type, GraphQL::DEPRECATED_STRING_TYPE.to_list_type)
    end

    it "counts non-null types as subtypes of nullable parent types" do
      assert subtype?(Dummy::Milk.graphql_definition, Dummy::Milk.graphql_definition.to_non_null_type)
      assert subtype?(Dummy::Edible.graphql_definition, Dummy::Milk.graphql_definition.to_non_null_type)
      assert subtype?(Dummy::Edible.graphql_definition.to_non_null_type, Dummy::Milk.graphql_definition.to_non_null_type)
      assert subtype?(
        GraphQL::DEPRECATED_STRING_TYPE.to_non_null_type.to_list_type,
        GraphQL::DEPRECATED_STRING_TYPE.to_non_null_type.to_list_type.to_non_null_type,
      )
    end
  end
end
