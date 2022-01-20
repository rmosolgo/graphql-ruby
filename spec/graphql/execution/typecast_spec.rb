# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::Typecast do
  describe ".subtype?" do
    def subtype?(*args)
      GraphQL::Execution::Typecast.subtype?(*args)
    end

    it "counts the same type as a subtype" do
      assert subtype?(Dummy::Milk.graphql_definition(silence_deprecation_warning: true), Dummy::Milk.graphql_definition(silence_deprecation_warning: true))
      assert !subtype?(Dummy::Milk.graphql_definition(silence_deprecation_warning: true), Dummy::Cheese.graphql_definition(silence_deprecation_warning: true))
      assert subtype?(Dummy::Milk.graphql_definition(silence_deprecation_warning: true).to_list_type.to_non_null_type, Dummy::Milk.graphql_definition(silence_deprecation_warning: true).to_list_type.to_non_null_type)
    end

    it "counts member types as subtypes" do
      assert subtype?(Dummy::Edible.graphql_definition(silence_deprecation_warning: true), Dummy::Cheese.graphql_definition(silence_deprecation_warning: true))
      assert subtype?(Dummy::Edible.graphql_definition(silence_deprecation_warning: true), Dummy::Milk.graphql_definition(silence_deprecation_warning: true))
      assert subtype?(Dummy::DairyProduct.graphql_definition(silence_deprecation_warning: true), Dummy::Milk.graphql_definition(silence_deprecation_warning: true))
      assert subtype?(Dummy::DairyProduct.graphql_definition(silence_deprecation_warning: true), Dummy::Cheese.graphql_definition(silence_deprecation_warning: true))

      assert !subtype?(Dummy::DairyAppQuery.graphql_definition(silence_deprecation_warning: true), Dummy::DairyProduct.graphql_definition(silence_deprecation_warning: true))
      assert !subtype?(Dummy::Cheese.graphql_definition(silence_deprecation_warning: true), Dummy::DairyProduct.graphql_definition(silence_deprecation_warning: true))
      assert !subtype?(Dummy::Edible.graphql_definition(silence_deprecation_warning: true), Dummy::DairyProduct.graphql_definition(silence_deprecation_warning: true))
      assert !subtype?(Dummy::Edible.graphql_definition(silence_deprecation_warning: true), GraphQL::DEPRECATED_STRING_TYPE)
      assert !subtype?(Dummy::Edible.graphql_definition(silence_deprecation_warning: true), Dummy::DairyProductInput.graphql_definition(silence_deprecation_warning: true))
    end

    it "counts lists as subtypes if their inner types are subtypes" do
      assert subtype?(Dummy::Edible.graphql_definition(silence_deprecation_warning: true).to_list_type, Dummy::Milk.graphql_definition(silence_deprecation_warning: true).to_list_type)
      assert subtype?(Dummy::DairyProduct.graphql_definition(silence_deprecation_warning: true).to_list_type, Dummy::Milk.graphql_definition(silence_deprecation_warning: true).to_list_type)
      assert !subtype?(Dummy::Cheese.graphql_definition(silence_deprecation_warning: true).to_list_type, Dummy::DairyProduct.graphql_definition(silence_deprecation_warning: true).to_list_type)
      assert !subtype?(Dummy::Edible.graphql_definition(silence_deprecation_warning: true).to_list_type, Dummy::DairyProduct.graphql_definition(silence_deprecation_warning: true).to_list_type)
      assert !subtype?(Dummy::Edible.graphql_definition(silence_deprecation_warning: true).to_list_type, GraphQL::DEPRECATED_STRING_TYPE.to_list_type)
    end

    it "counts non-null types as subtypes of nullable parent types" do
      assert subtype?(Dummy::Milk.graphql_definition(silence_deprecation_warning: true), Dummy::Milk.graphql_definition(silence_deprecation_warning: true).to_non_null_type)
      assert subtype?(Dummy::Edible.graphql_definition(silence_deprecation_warning: true), Dummy::Milk.graphql_definition(silence_deprecation_warning: true).to_non_null_type)
      assert subtype?(Dummy::Edible.graphql_definition(silence_deprecation_warning: true).to_non_null_type, Dummy::Milk.graphql_definition(silence_deprecation_warning: true).to_non_null_type)
      assert subtype?(
        GraphQL::DEPRECATED_STRING_TYPE.to_non_null_type.to_list_type,
        GraphQL::DEPRECATED_STRING_TYPE.to_non_null_type.to_list_type.to_non_null_type,
      )
    end
  end
end
