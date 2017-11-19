# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::Typecast do
  describe ".subtype?" do
    def subtype?(*args)
      GraphQL::Execution::Typecast.subtype?(*args)
    end

    it "counts the same type as a subtype" do
      assert subtype?(Dummy::Types::MilkType, Dummy::Types::MilkType)
      assert !subtype?(Dummy::Types::MilkType, Dummy::Types::CheeseType)
      assert subtype?(Dummy::Types::MilkType.to_list_type.to_non_null_type, Dummy::Types::MilkType.to_list_type.to_non_null_type)
    end

    it "counts member types as subtypes" do
      assert subtype?(Dummy::Types::EdibleInterface, Dummy::Types::CheeseType)
      assert subtype?(Dummy::Types::EdibleInterface, Dummy::Types::MilkType)
      assert subtype?(Dummy::DairyProductUnion, Dummy::Types::MilkType)
      assert subtype?(Dummy::DairyProductUnion, Dummy::Types::CheeseType)

      assert !subtype?(Dummy::DairyAppQueryType, Dummy::DairyProductUnion)
      assert !subtype?(Dummy::Types::CheeseType, Dummy::DairyProductUnion)
      assert !subtype?(Dummy::Types::EdibleInterface, Dummy::DairyProductUnion)
      assert !subtype?(Dummy::Types::EdibleInterface, GraphQL::STRING_TYPE)
      assert !subtype?(Dummy::Types::EdibleInterface, Dummy::DairyProductInputType)
    end

    it "counts lists as subtypes if their inner types are subtypes" do
      assert subtype?(Dummy::Types::EdibleInterface.to_list_type, Dummy::Types::MilkType.to_list_type)
      assert subtype?(Dummy::DairyProductUnion.to_list_type, Dummy::Types::MilkType.to_list_type)
      assert !subtype?(Dummy::Types::CheeseType.to_list_type, Dummy::DairyProductUnion.to_list_type)
      assert !subtype?(Dummy::Types::EdibleInterface.to_list_type, Dummy::DairyProductUnion.to_list_type)
      assert !subtype?(Dummy::Types::EdibleInterface.to_list_type, GraphQL::STRING_TYPE.to_list_type)
    end

    it "counts non-null types as subtypes of nullable parent types" do
      assert subtype?(Dummy::Types::MilkType, Dummy::Types::MilkType.to_non_null_type)
      assert subtype?(Dummy::Types::EdibleInterface, Dummy::Types::MilkType.to_non_null_type)
      assert subtype?(Dummy::Types::EdibleInterface.to_non_null_type, Dummy::Types::MilkType.to_non_null_type)
      assert subtype?(
        GraphQL::STRING_TYPE.to_non_null_type.to_list_type,
        GraphQL::STRING_TYPE.to_non_null_type.to_list_type.to_non_null_type,
      )
    end
  end
end
