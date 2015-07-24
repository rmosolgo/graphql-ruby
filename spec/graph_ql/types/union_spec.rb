require 'spec_helper'

describe GraphQL::Union do
  let(:type_1) { OpenStruct.new(kind: GraphQL::TypeKinds::OBJECT)}
  let(:type_2) { OpenStruct.new(kind: GraphQL::TypeKinds::OBJECT)}
  let(:union) { GraphQL::Union.new("MyUnion", "Some items", [type_1, type_2]) }
  it 'has a name' do
    assert_equal("MyUnion", union.name)
  end

  it 'infers type from an object' do
    assert_equal(CheeseType, DairyProductUnion.resolve_type(CHEESES[1]))
  end
end
