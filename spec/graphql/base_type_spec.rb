require "spec_helper"

describe GraphQL::BaseType do
  it "becomes non-null with !" do
    type = GraphQL::EnumType.new
    non_null_type = !type
    assert_equal(GraphQL::TypeKinds::NON_NULL, non_null_type.kind)
    assert_equal(type, non_null_type.of_type)
    assert_equal(GraphQL::TypeKinds::NON_NULL, (!GraphQL::STRING_TYPE).kind)
  end

  it "can be compared" do
    assert_equal(!GraphQL::INT_TYPE, !GraphQL::INT_TYPE)
    refute_equal(!GraphQL::FLOAT_TYPE, GraphQL::FLOAT_TYPE)
    assert_equal(
      GraphQL::ListType.new(of_type: MilkType),
      GraphQL::ListType.new(of_type: MilkType)
    )
    refute_equal(
      GraphQL::ListType.new(of_type: MilkType),
      GraphQL::ListType.new(of_type: !MilkType)
    )
  end
end
