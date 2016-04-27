require 'spec_helper'

describe GraphQL::UnionType do
  let(:type_1) { OpenStruct.new(kind: GraphQL::TypeKinds::OBJECT)}
  let(:type_2) { OpenStruct.new(kind: GraphQL::TypeKinds::OBJECT)}
  let(:type_3) { OpenStruct.new(kind: GraphQL::TypeKinds::SCALAR)}
  let(:union) {
    types = [type_1, type_2]
    GraphQL::UnionType.define {
      name("MyUnion")
      description("Some items")
      possible_types(types)
    }
  }
  it 'has a name' do
    assert_equal("MyUnion", union.name)
  end

  it 'infers type from an object' do
    assert_equal(CheeseType, DairyProductUnion.resolve_type(CHEESES[1], OpenStruct.new(schema: DummySchema)))
  end

  it '#include? returns true if type in in possible_types' do
    assert union.include?(type_1)
  end

  it '#include? returns false if type is not in possible_types' do
    assert_equal(false, union.include?(type_3))
  end
end
