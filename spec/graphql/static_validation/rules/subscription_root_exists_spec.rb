require "spec_helper"

describe GraphQL::StaticValidation::SubscriptionRootExists do
  let(:query_string) {%|
    subscription {
      test
    }
  |}

  let(:schema) {
    query_root = GraphQL::Field.define do
      name "Query"
      description "Query root of the system"
    end

    GraphQL::Schema.define do
      query query_root
    end
  }

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: schema, rules: [GraphQL::StaticValidation::SubscriptionRootExists]) }
  let(:query) { GraphQL::Query.new(schema, query_string) }
  let(:errors) { validator.validate(query)[:errors] }

  it "errors when a subscription is performed on a schema without a subscription root" do
    assert_equal(1, errors.length)
    missing_subscription_root_error = {
      "message"=>"Schema is not configured for subscriptions",
      "locations"=>[{"line"=>2, "column"=>5}],
      "fields"=>["subscription"],
    }
    assert_includes(errors, missing_subscription_root_error)
  end
end
