# frozen_string_literal: true
require "spec_helper"

if testing_rails? && defined?(ActionCable) # not all rails versions have ActionCable
  describe GraphQL::Subscriptions::ActionCableSubscriptions do
    class ActionCableSchema < GraphQL::Schema
      class Tick < GraphQL::Schema::Subscription
        field :value, Integer, null: false
      end

      class Subscription < GraphQL::Schema::Object
        field :tick, subscription: Tick
      end

      use GraphQL::Subscriptions::ActionCableSubscriptions
    end

    it "handles `execute_update` for a missing subscription ID" do
      res = ActionCableSchema.subscriptions.execute_update("nonsense-id", {}, {})
      assert_nil res
    end
  end
end
