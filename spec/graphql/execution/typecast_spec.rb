require "spec_helper"

describe GraphQL::Execution::Typecast do

  let(:schema) { DummySchema }
  let(:context) { GraphQL::Query::Context.new(query: OpenStruct.new(schema: schema), values: nil) }

  it "resolves correctly when both types are the same" do
    assert GraphQL::Execution::Typecast.compatible?(MILKS[1], MilkType, MilkType, context)
  end

  it "resolves correcty when current type is UnionType and value resolves to potential type" do
    assert GraphQL::Execution::Typecast.compatible?(MILKS[1], DairyProductUnion, MilkType, context)
  end

  it "resolves correcty when potential type is UnionType and current type is a member of that union" do
    assert GraphQL::Execution::Typecast.compatible?(MILKS[1], MilkType, DairyProductUnion, context)
  end

  it "resolve correctly when current type is an Interface and it resolves to potential type" do
    assert GraphQL::Execution::Typecast.compatible?(MILKS[1], CheeseType, EdibleInterface, context)
  end

  it "resolve correctly when potential type is an Interface and current type implements it" do
    assert GraphQL::Execution::Typecast.compatible?(CHEESES[1], EdibleInterface, CheeseType, context)
  end

  it "resolve correctly when potential type is an Interface and current type implements it" do
    assert GraphQL::Execution::Typecast.compatible?(MILKS[1], EdibleInterface, CheeseType, context)
  end

end
