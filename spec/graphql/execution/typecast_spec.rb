# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::Typecast do
  let(:milk_value) { MILKS[1] }
  let(:cheese_value) { CHEESES[1] }

  let(:schema) { DummySchema }
  let(:context) { GraphQL::Query::Context.new(query: OpenStruct.new(schema: schema), values: nil) }

  def compatible?(*args)
    GraphQL::Execution::Typecast.compatible?(*args)
  end

  it "resolves correctly when both types are the same" do
    assert compatible?(MilkType, MilkType, context)

    assert !compatible?(MilkType, CheeseType, context)
  end

  it "resolves a union type to a matching member" do
    assert compatible?(DairyProductUnion, MilkType, context)
    assert compatible?(DairyProductUnion, CheeseType, context)

    assert !compatible?(DairyProductUnion, GraphQL::INT_TYPE, context)
    assert !compatible?(DairyProductUnion, HoneyType, context)
  end

  it "resolves correcty when potential type is UnionType and current type is a member of that union" do
    assert compatible?(MilkType, DairyProductUnion, context)
    assert compatible?(CheeseType, DairyProductUnion, context)

    assert !compatible?(QueryType, DairyProductUnion, context)
    assert !compatible?(EdibleInterface, DairyProductUnion, context)
  end

  it "resolves an object type to one of its interfaces" do
    assert compatible?(CheeseType, EdibleInterface, context)
    assert compatible?(MilkType, EdibleInterface, context)

    assert !compatible?(QueryType, EdibleInterface, context)
    assert !compatible?(LocalProductInterface, EdibleInterface, context)
  end

  it "resolves an interface to a matching member" do
    assert compatible?(EdibleInterface, CheeseType, context)
    assert compatible?(EdibleInterface, MilkType, context)

    assert !compatible?(EdibleInterface, GraphQL::STRING_TYPE, context)
    assert !compatible?(EdibleInterface, DairyProductInputType, context)
  end
end
