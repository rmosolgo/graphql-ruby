# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::Typecast do
  let(:milk_value) { MILKS[1] }
  let(:cheese_value) { CHEESES[1] }

  let(:schema) { Dummy::Schema }
  let(:context) { GraphQL::Query::Context.new(query: OpenStruct.new(schema: schema), values: nil) }

  describe "compatible" do
    def compatible?(*args)
      GraphQL::Execution::Typecast.compatible?(*args)
    end

    it "resolves correctly when both types are the same" do
      assert compatible?(Dummy::MilkType, Dummy::MilkType, context)

      assert !compatible?(Dummy::MilkType, Dummy::CheeseType, context)
    end

    it "resolves a union type to a matching member" do
      assert compatible?(Dummy::DairyProductUnion, Dummy::MilkType, context)
      assert compatible?(Dummy::DairyProductUnion, Dummy::CheeseType, context)

      assert !compatible?(Dummy::DairyProductUnion, GraphQL::INT_TYPE, context)
      assert !compatible?(Dummy::DairyProductUnion, Dummy::HoneyType, context)
    end

    it "resolves correcty when potential type is UnionType and current type is a member of that union" do
      assert compatible?(Dummy::MilkType, Dummy::DairyProductUnion, context)
      assert compatible?(Dummy::CheeseType, Dummy::DairyProductUnion, context)

      assert !compatible?(Dummy::DairyAppQueryType, Dummy::DairyProductUnion, context)
      assert !compatible?(Dummy::EdibleInterface, Dummy::DairyProductUnion, context)
    end

    it "resolves an object type to one of its interfaces" do
      assert compatible?(Dummy::CheeseType, Dummy::EdibleInterface, context)
      assert compatible?(Dummy::MilkType, Dummy::EdibleInterface, context)

      assert !compatible?(Dummy::DairyAppQueryType, Dummy::EdibleInterface, context)
      assert !compatible?(Dummy::LocalProductInterface, Dummy::EdibleInterface, context)
    end

    it "resolves an interface to a matching member" do
      assert compatible?(Dummy::EdibleInterface, Dummy::CheeseType, context)
      assert compatible?(Dummy::EdibleInterface, Dummy::MilkType, context)

      assert !compatible?(Dummy::EdibleInterface, GraphQL::STRING_TYPE, context)
      assert !compatible?(Dummy::EdibleInterface, Dummy::DairyProductInputType, context)
    end
  end

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
