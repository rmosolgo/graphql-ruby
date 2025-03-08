# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::SubscriptionRootExistsAndSingleSubscriptionSelection do
  include StaticValidationHelpers

  let(:query_string) {%|
    subscription {
      test
    }
  |}

  let(:schema) {
    Class.new(GraphQL::Schema) do
      query_root = Class.new(GraphQL::Schema::Object) do
        graphql_name "Query"
      end

      query query_root
    end
  }

  it "errors when a subscription is performed on a schema without a subscription root" do
    assert_equal(1, errors.length)
    missing_subscription_root_error = {
      "message"=>"Schema is not configured for subscriptions",
      "locations"=>[{"line"=>2, "column"=>5}],
      "path"=>["subscription"],
      "extensions"=>{"code"=>"missingSubscriptionConfiguration"}
    }
    assert_includes(errors, missing_subscription_root_error)
  end

  describe "when multiple subscription selections" do
    let(:query_string) {
      "subscription { subscription1 subscription2 }"
    }

    let(:schema) {
      Class.new(GraphQL::Schema) do
        subscription(Class.new(GraphQL::Schema::Object) do
          graphql_name "Subscription"
          field :subscription1, String
          field :subscription2, String
        end)
      end
    }

    it "returns an error" do
      expected_errs = [
        {
          "message" => "A subscription operation may only have one selection",
          "locations" => [{"line" => 1, "column" => 1}],
          "path" => ["subscription"],
          "extensions" => {"code" => "notSingleSubscription"}
        }
      ]
      assert_equal(expected_errs, errors)
    end
  end
end
