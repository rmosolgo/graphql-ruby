require 'spec_helper'

describe GraphQL::ListType do
  let(:float_list) { GraphQL::ListType.new(of_type: GraphQL::FLOAT_TYPE) }

  it 'coerces a non-list into a list' do
    assert_equal([123.4], float_list.coerce_input(123.4))
  end

  it 'coerces elements in the list' do
    assert_equal([1.0, 2.0, 3.0].inspect, float_list.coerce_input([1, 2, 3]).inspect)
  end
end
