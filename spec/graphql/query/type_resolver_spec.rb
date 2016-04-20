require 'spec_helper'

describe GraphQL::Query::TypeResolver do
  it 'resolves correcty when child_type is UnionType' do
    type = GraphQL::Query::TypeResolver.new(MILKS[1], DairyProductUnion, MilkType, nil).type
    assert_equal(MilkType, type)
  end
end
