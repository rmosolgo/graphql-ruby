require 'spec_helper'

describe GraphQL::Union do
  let(:type_1) { OpenStruct.new(kind: GraphQL::TypeKinds::OBJECT)}
  let(:type_2) { OpenStruct.new(kind: GraphQL::TypeKinds::OBJECT)}
  let(:union) { GraphQL::Union.new("MyUnion", [type_1, type_2]) }
  it 'has a name' do
    assert_equal("MyUnion", union.name)
  end

  it 'identifies members' do
    assert(union.include?(type_1))
    assert(!union.include?(:type_3))
  end

  it 'must be 2+ types' do
    assert_raises(ArgumentError) { GraphQL::Union.new("Something", [type_1])}
  end

  it 'must be all object types' do
    assert_raises(ArgumentError) { GraphQL::Union.new("Something", [type_1, type_2, union])}
  end
end
