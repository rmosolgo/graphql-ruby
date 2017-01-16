# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::Typecast do
  let(:milk_value) { MILKS[1] }
  let(:cheese_value) { CHEESES[1] }

  let(:schema) { Dummy::Schema }
  let(:context) { GraphQL::Query::Context.new(query: OpenStruct.new(schema: schema), values: nil) }

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
