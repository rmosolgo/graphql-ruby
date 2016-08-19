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
    assert compatible?(milk_value, MilkType, MilkType, context)
    assert !compatible?(milk_value, MilkType, CheeseType, context)
  end

  it "resolves a union type to a matching member" do
    assert compatible?(milk_value, DairyProductUnion, MilkType, context)
    assert compatible?(cheese_value, DairyProductUnion, CheeseType, context)

    assert !compatible?(cheese_value, DairyProductUnion, MilkType, context)
    assert !compatible?(nil, DairyProductUnion, MilkType, context)
  end

  it "resolves correcty when potential type is UnionType and current type is a member of that union" do
    assert compatible?(milk_value, MilkType, DairyProductUnion, context)
    assert compatible?(cheese_value, CheeseType, DairyProductUnion, context)

    # assert !compatible?(nil, CheeseType, DairyProductUnion, context)
    # assert !compatible?(cheese_value, MilkType, DairyProductUnion, context)
  end

  it "resolves an object type to one of its interfaces" do
    assert compatible?(cheese_value, CheeseType, EdibleInterface, context)
    assert compatible?(milk_value, MilkType, EdibleInterface, context)

    # assert !compatible?(nil, MilkType, EdibleInterface, context)
    # assert !compatible?(milk_value, CheeseType, EdibleInterface, context)
  end

  it "resolves an interface to a matching member" do
    assert compatible?(cheese_value, EdibleInterface, CheeseType, context)
    assert compatible?(milk_value, EdibleInterface, MilkType, context)

    assert !compatible?(nil, EdibleInterface, MilkType, context)
    assert !compatible?(cheese_value, EdibleInterface, MilkType, context)
  end
end
