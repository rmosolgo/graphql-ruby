# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::NoDeprecatedFields do
  include StaticValidationHelpers
  let(:query_string) {"
    query getCheese {
      okCheese: cheese(id: 1) { flavor }
      cheese(id: 1) { source fatContent }
    }
  "}

  it "finds deprecated fields" do
    assert_equal(1, errors_optional.length)

    query_root_error = {
      "message"=>"Field 'fatContent' is deprecated: 'Diet fashion has changed'",
      "locations"=>[{"line"=>4, "column"=>30}],
      "fields"=>["query getCheese", "cheese", "fatContent"],
    }
    assert_includes(errors_optional, query_root_error)
  end

  def errors_optional
    errors(
      validator: GraphQL::StaticValidation::Validator.new(schema: schema, rules: GraphQL::StaticValidation::OPTIONAL_RULES)
    )
  end
end
