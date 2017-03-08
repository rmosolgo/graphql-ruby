# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::Typecast do
  describe ".subtype?" do
    def subtype?(*args)
      GraphQL::Execution::Typecast.subtype?(*args)
    end

    it "counts the same type as a subtype" do
      assert subtype?(Dummy::MilkType, Dummy::MilkType)
      assert !subtype?(Dummy::MilkType, Dummy::CheeseType)
      assert subtype?(Dummy::MilkType.to_list_type.to_non_null_type, Dummy::MilkType.to_list_type.to_non_null_type)
    end

    it "counts member types as subtypes" do
      assert subtype?(Dummy::EdibleInterface, Dummy::CheeseType)
      assert subtype?(Dummy::EdibleInterface, Dummy::MilkType)
      assert subtype?(Dummy::DairyProductUnion, Dummy::MilkType)
      assert subtype?(Dummy::DairyProductUnion, Dummy::CheeseType)

      assert !subtype?(Dummy::DairyAppQueryType, Dummy::DairyProductUnion)
      assert !subtype?(Dummy::CheeseType, Dummy::DairyProductUnion)
      assert !subtype?(Dummy::EdibleInterface, Dummy::DairyProductUnion)
      assert !subtype?(Dummy::EdibleInterface, GraphQL::STRING_TYPE)
      assert !subtype?(Dummy::EdibleInterface, Dummy::DairyProductInputType)
    end

    it "counts lists as subtypes if their inner types are subtypes" do
      assert subtype?(Dummy::EdibleInterface.to_list_type, Dummy::MilkType.to_list_type)
      assert subtype?(Dummy::DairyProductUnion.to_list_type, Dummy::MilkType.to_list_type)
      assert !subtype?(Dummy::CheeseType.to_list_type, Dummy::DairyProductUnion.to_list_type)
      assert !subtype?(Dummy::EdibleInterface.to_list_type, Dummy::DairyProductUnion.to_list_type)
      assert !subtype?(Dummy::EdibleInterface.to_list_type, GraphQL::STRING_TYPE.to_list_type)
    end

    it "counts non-null types as subtypes of nullable parent types" do
      assert subtype?(Dummy::MilkType, Dummy::MilkType.to_non_null_type)
      assert subtype?(Dummy::EdibleInterface, Dummy::MilkType.to_non_null_type)
      assert subtype?(Dummy::EdibleInterface.to_non_null_type, Dummy::MilkType.to_non_null_type)
      assert subtype?(
        GraphQL::STRING_TYPE.to_non_null_type.to_list_type,
        GraphQL::STRING_TYPE.to_non_null_type.to_list_type.to_non_null_type,
      )
    end
  end
end
