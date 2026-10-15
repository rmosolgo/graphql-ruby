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

  describe "when a subscription root is configured" do
    let(:query_string) {
      "subscription { subscription1 subscription2 }"
    }

    let(:schema) {
      Class.new(GraphQL::Schema) do
        subscription_interface = Module.new do
          include GraphQL::Schema::Interface
          graphql_name "SubscriptionFields"
          field :subscription1, String
          field :subscription2, String
        end
        payload_type = Class.new(GraphQL::Schema::Object) do
          graphql_name "SubscriptionPayload"
          field :value, String
        end

        subscription(Class.new(GraphQL::Schema::Object) do
          graphql_name "Subscription"
          implements subscription_interface
          field :subscription1, String
          field :subscription2, String
          field :subscription3, payload_type
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

    {
      "a named fragment" => "subscription { ...F } fragment F on Subscription { subscription1 subscription2 }",
      "an interface fragment" => "subscription { ...F } fragment F on SubscriptionFields { subscription1 subscription2 }",
      "an inline fragment" => "subscription { ... on Subscription { subscription1 subscription2 } }",
      "nested fragments" => "subscription { ...F } fragment F on Subscription { ... on Subscription { subscription1 ...G } } fragment G on Subscription { subscription2 }",
      "distinct aliases" => "subscription { ...F } fragment F on Subscription { first: subscription1 second: subscription1 }",
    }.each do |description, source|
      describe "with multiple root fields in #{description}" do
        let(:query_string) { source }

        it "rejects the subscription" do
          assert_equal ["A subscription operation may only have one selection"], error_messages
          assert_equal ["notSingleSubscription"], errors.map { |error| error["extensions"]["code"] }
        end
      end
    end

    {
      "a direct field" => "subscription { __typename }",
      "an aliased field" => "subscription { name: __typename }",
      "nested fragments" => "subscription { ...F } fragment F on Subscription { ... on Subscription { name: __typename } }",
    }.each do |description, source|
      describe "with root introspection in #{description}" do
        let(:query_string) { source }

        it "rejects the subscription" do
          assert_equal ["A subscription operation may not select an introspection field"], error_messages
          assert_equal ["notSingleSubscription"], errors.map { |error| error["extensions"]["code"] }
        end
      end
    end

    {
      "an aliased root field" => "subscription { __event: subscription1 }",
      "a named fragment" => "subscription { ...F } fragment F on Subscription { subscription1 }",
      "an interface fragment" => "subscription { ...F } fragment F on SubscriptionFields { subscription1 }",
      "an inline fragment" => "subscription { ... { subscription1 } }",
      "repeated fields" => "subscription { subscription1 subscription1 }",
      "repeated fragment spreads" => "subscription { ...F ...F } fragment F on Subscription { subscription1 }",
      "overlapping fields and fragments" => "subscription { subscription1 ...F } fragment F on Subscription { subscription1 }",
      "a repeated alias" => "subscription { event: subscription1 ...F } fragment F on Subscription { event: subscription1 }",
      "nested fields and introspection" => "subscription { subscription3 { value __typename } }",
      "separate operations" => "subscription One { ...F } subscription Two { ...F } fragment F on Subscription { subscription1 }",
    }.each do |description, source|
      describe "with #{description}" do
        let(:query_string) { source }

        it "accepts a single root field" do
          assert_empty errors
        end
      end
    end

    describe "with a cyclic fragment" do
      let(:query_string) { "subscription { ...F } fragment F on Subscription { subscription1 ...F }" }

      it "leaves cycle validation to the fragment rule" do
        assert_equal ["infiniteLoop"], errors.map { |error| error["extensions"]["code"] }
      end
    end

    describe "with an undefined fragment" do
      let(:query_string) { "subscription { subscription1 ...Missing }" }

      it "leaves undefined fragment validation to the fragment rule" do
        assert_equal ["Fragment Missing was used, but not defined"], error_messages
      end
    end

    describe "when validating only this rule" do
      let(:query_string) { "subscription { ...F } fragment F on Subscription { subscription1 subscription2 }" }

      it "rejects fragment selections independently of other rules" do
        validator = GraphQL::StaticValidation::Validator.new(schema: schema, rules: [GraphQL::StaticValidation::SubscriptionRootExistsAndSingleSubscriptionSelection])
        query = GraphQL::Query.new(schema, query_string)
        assert_equal ["notSingleSubscription"], validator.validate(query)[:errors].map(&:code)
      end
    end
  end
end
