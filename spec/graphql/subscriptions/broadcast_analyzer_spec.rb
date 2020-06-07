# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Subscriptions::BroadcastAnalyzer do
  class BroadcastTestSchema < GraphQL::Schema
    module Throwable
      include GraphQL::Schema::Interface
      field :weight, Integer, null: false
    end

    class Javelin < GraphQL::Schema::Object
      implements Throwable
    end

    class Shot < GraphQL::Schema::Object
      implements Throwable
    end

    class Query < GraphQL::Schema::Object
      field :throwable, Throwable, null: true
    end

    class Mutation < GraphQL::Schema::Object
      field :noop, String, null: true
    end

    class Subscription < GraphQL::Schema::Object
      class ThrowableWasThrown < GraphQL::Schema::Subscription
        field :throwable, Throwable, null: false
      end

      field :throwable_was_thrown, subscription: ThrowableWasThrown
    end

    query(Query)
    mutation(Mutation)
    subscription(Subscription)
    use GraphQL::Execution::Interpreter
    use GraphQL::Analysis::AST
    use GraphQL::Subscriptions, broadcast: true, default_broadcastable: true
  end


  def broadcastable?(query_str)
    query = GraphQL::Query.new(BroadcastTestSchema, query_str)
    GraphQL::Analysis::AST.analyze_query(query, BroadcastTestSchema.query_analyzers)
    query.context.namespace(:subscriptions)[:subscription_broadcastable]
  end

  it "doesn't run for non-subscriptions" do
    assert_nil broadcastable?("{ __typename }")
    assert_nil broadcastable?("mutation { __typename }")
    assert_equal true, broadcastable?("subscription { __typename }")
  end

  describe "when the default is false" do
    it "applies default false when any field is not tagged"
    it "returns true when all fields are tagged true"
  end

  describe "when the default is true" do
    it "returns false when any field is tagged false"
    it "returns true no field is tagged false"
  end

  describe "abstract types" do
    describe "when a field returns an interface" do
      it "requires all object type fields to be broadcastable"
      it "is ok if all explicitly-named object fields are broadcastable"
      it "is false if any explicitly-named object fields are broadcastable"
    end
  end
end
