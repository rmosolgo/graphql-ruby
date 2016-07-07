require "spec_helper"

describe GraphQL::Schema::ReduceResolvedClassNames do
  def reduce_resolved_class_names(types)
    GraphQL::Schema::ReduceResolvedClassNames.reduce(types)
  end

  it "finds resolved_class_name from arguments" do
    result = reduce_resolved_class_names([QueryType])
    assert_equal("Cheese", result["Cheese"])
    assert_equal("Acme::Post", result["Post"])
  end
end
