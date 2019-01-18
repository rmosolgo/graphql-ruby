# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Subscription do
  class SubscriptionFieldSchema < GraphQL::Subscription
    TOOTS = []
    ALL_USERS = {
      "dhh" => {handle: "dhh"}
      "matz" => {handle: "matz"}
      "_why" => {handle: "_why", private: true}
    }

    USERS = {}

    class Toot < GraphQL::Schema::Object
      field :handle, String, null: false
      field :body, String, null: false
    end

    class Query < GraphQL::Schema::Object
      field :toots, [Toot], null: false

      def toots
        TOOTS
      end
    end

    class BaseSubscription < GraphQL::Schema::Resolver
    end

    class TootWasTooted < BaseSubscription
      argument :handle, String, required: true, loads: true, as: :user
      field :toot, Toot, null: false

      # Can't subscribe to private users
      def authorized?(user:)
        !user[:private]
      end

      # TODO maybe this is default
      def subscribe(user:)
        :no_response
      end

      def update(user:)
        if context[:viewer] == user
          # don't update for one's own toots
          :no_update
        else
          super
        end
      end
    end

    class Subscription < GraphQL::Schema::Object
      field :toot_was_tooted, subscription: TootWasTooted
    end

    class Mutation < GraphQL::Schema::Object
      field :toot, Toot, null: false do
        argument :body, String, required: true
      end

      def toot(body:)
        handle = context[:viewer][:handle]
        toot = { handle: handle, body: body }
        TOOTS << toot
        SubscriptionFieldSchema.trigger(:toot_was_tooted, {handle: handle}, toot)
      end
    end

    query(Query)
    mutation(Mutation)
    subscription(Subscription)
  end

  before do
    # Reset databases
    SubscriptionFieldSchema::TOOTS.clear
    SubscriptionFieldSchema::USERS.merge!(SubscriptionFieldSchema::ALL_USERS)
  end

  it "generates a return type"
  it "can use a premade `payload_type`"

  describe "#authorized?" do
    it "fails the subscription if it fails the initial check"
    it "unsubscribes if an update fails this check"
  end

  describe "initial subscription" do
    it "calls #subscribe for the initial subscription and returns the result"
    it "rejects the subscription if #subscribe raises an error"
    it "sends no initial response if :no_response is returned"
  end

  describe "updates" do
    it "updates with `object` by default"
    it "updates with the returned value"
    it "skips the update if `:no_update` is returned"
  end

  describe "loads:" do
    it "unsubscribes if a `loads:` argument is not found"
  end
end
