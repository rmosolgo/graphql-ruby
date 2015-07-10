require 'spec_helper'

describe GraphQL::Interface do
  let(:interface) { Edible }
  it 'has possible types' do
    assert_equal([CheeseType, MilkType], interface.possible_types)
  end

  it 'resolves types for objects' do
    assert_equal(CheeseType, interface.resolve_type(CHEESES.values.first))
    assert_equal(MilkType, interface.resolve_type(MILKS.values.first))
  end
end
