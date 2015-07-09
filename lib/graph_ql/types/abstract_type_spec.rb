require 'spec_helper'

describe GraphQL::AbstractType do
  let(:type) { GraphQL::AbstractType.new }
  it 'becomes non-null with !' do
    non_null_type = !type
    assert_equal(GraphQL::TypeKinds::NON_NULL, non_null_type.kind)
    assert_equal(type, non_null_type.of_type)
    assert_equal(GraphQL::TypeKinds::NON_NULL, (!GraphQL::STRING_TYPE).kind)
  end
end
