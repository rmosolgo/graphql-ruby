# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Subscription do
  class SubscriptionFieldSchema < GraphQL::Schema
    TOOTS = []
    ALL_USERS = {
      "dhh" => {handle: "dhh", private: false},
      "matz" => {handle: "matz", private: false},
      "_why" => {handle: "_why", private: true},
    }

    USERS = {}

    class User < GraphQL::Schema::Object
      field :handle, String, null: false
      field :private, Boolean, null: false
    end

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

    class BaseSubscription < GraphQL::Schema::Subscription
    end

    class TootWasTooted < BaseSubscription
      argument :handle, String, required: true, loads: User, as: :user
      field :toot, Toot, null: false
      field :user, User, null: false
      # Can't subscribe to private users
      def authorized?(user:)
        if user[:private]
          raise GraphQL::ExecutionError, "Can't subscribe to private user"
        else
          true
        end
      end

      def subscribe(user:)
        if context[:prohibit_subscriptions]
          raise GraphQL::ExecutionError, "You don't have permission to subscribe"
        else
          # Default is to return :no_response
          super
        end
      end

      def update(user:)
        if context[:viewer] == user
          # don't update for one's own toots
          :no_update
        else
          {
            toot: object,
            user: USERS[object[:handle]],
          }
        end
      end
    end

    # Test initial response, which returns all users
    class UsersJoined < BaseSubscription
      class UsersJoinedManualPayload < GraphQL::Schema::Object
        field :users, [User], null: true,
          description: "Includes newly-created users, or all users on the initial load"
      end

      payload_type UsersJoinedManualPayload

      def subscribe
        { users: USERS.values }
      end
    end

    class Subscription < GraphQL::Schema::Object
      extend GraphQL::Subscriptions::SubscriptionRoot
      field :toot_was_tooted, subscription: TootWasTooted
      field :users_joined, subscription: UsersJoined
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
    use GraphQL::Execution::Interpreter
    use GraphQL::Analysis::AST

    def self.object_from_id(id, ctx)
      USERS[id]
    end


    class InMemorySubscriptions < GraphQL::Subscriptions
      SUBSCRIPTION_REGISTRY = {}

      EVENT_REGISTRY = Hash.new { |h, k| h[k] = [] }

      def write_subscription(query, events)
        subscription_id = build_id
        events.each do |ev|
          EVENT_REGISTRY[ev.topic] << subscription_id
        end
        SUBSCRIPTION_REGISTRY[subscription_id] = [query, events]
      end

      def each_subscription_id(event)
        EVENT_REGISTRY[event.topic].each do |sub_id|
          yield(sub_id)
        end
      end

      def deliver(subscription_id, result, context)
      end
    end

    use InMemorySubscriptions
  end

  def exec_query(*args)
    SubscriptionFieldSchema.execute(*args)
  end

  def in_memory_subscription_count
    SubscriptionFieldSchema::InMemorySubscriptions::SUBSCRIPTION_REGISTRY.size
  end

  before do
    # Reset databases
    SubscriptionFieldSchema::TOOTS.clear
    SubscriptionFieldSchema::USERS.merge!(SubscriptionFieldSchema::ALL_USERS)
    SubscriptionFieldSchema::InMemorySubscriptions::SUBSCRIPTION_REGISTRY.clear
    SubscriptionFieldSchema::InMemorySubscriptions::EVENT_REGISTRY.clear
  end

  it "generates a return type" do
    return_type = SubscriptionFieldSchema::TootWasTooted.payload_type
    assert_equal "TootWasTootedPayload", return_type.graphql_name
    assert_equal ["toot", "user"], return_type.fields.keys
  end

  it "can use a premade `payload_type`" do
    return_type = SubscriptionFieldSchema::UsersJoined.payload_type
    assert_equal "UsersJoinedManualPayload", return_type.graphql_name
    assert_equal ["users"], return_type.fields.keys
    assert_equal SubscriptionFieldSchema::UsersJoined::UsersJoinedManualPayload, return_type
  end

  describe "initial subscription" do
    it "calls #subscribe for the initial subscription and returns the result" do
      res = exec_query <<-GRAPHQL
      subscription {
        usersJoined {
          users {
            handle
          }
        }
      }
      GRAPHQL

      assert_equal ["dhh", "matz", "_why"], res["data"]["usersJoined"]["users"].map { |u| u["handle"] }
      assert_equal 1, in_memory_subscription_count
    end

    it "rejects the subscription if #subscribe raises an error" do
      res = exec_query <<-GRAPHQL, context: { prohibit_subscriptions: true }
      subscription {
        tootWasTooted(handle: "matz") {
          toot { body }
        }
      }
      GRAPHQL

      expected_response = {
        "data"=>nil,
        "errors"=>[
          {
            "message"=>"You don't have permission to subscribe",
            "locations"=>[{"line"=>2, "column"=>9}],
            "path"=>["tootWasTooted"]
          }
        ]
      }

      assert_equal(expected_response, res)
      assert_equal 0, in_memory_subscription_count
    end

    it "doesn't subscribe if `loads:` fails" do
      res = exec_query <<-GRAPHQL
      subscription {
        tootWasTooted(handle: "jack") {
          toot { body }
        }
      }
      GRAPHQL

      expected_response = {
        "data" => nil,
        "errors" => [
          {
            "message"=>"No object found for `handle: \"jack\"`",
            "locations"=>[{"line"=>2, "column"=>9}],
            "path"=>["tootWasTooted"]
          }
        ]
      }
      assert_equal(expected_response, res)
      assert_equal 0, in_memory_subscription_count
    end

    it "rejects if #authorized? fails" do
      res = exec_query <<-GRAPHQL
      subscription {
        tootWasTooted(handle: "_why") {
          toot { body }
        }
      }
      GRAPHQL
      expected_response = {
        "data"=>nil,
        "errors"=>[
          {
            "message"=>"Can't subscribe to private user",
            "locations"=>[{"line"=>2, "column"=>9}],
            "path"=>["tootWasTooted"]
          },
        ],
      }
      assert_equal(expected_response, res)
    end

    it "sends no initial response if :no_response is returned, which is the default" do
      assert_equal 0, in_memory_subscription_count

      res = exec_query <<-GRAPHQL
      subscription {
        tootWasTooted(handle: "matz") {
          toot { body }
        }
      }
      GRAPHQL
      assert_equal({"data" => {}}, res)
      assert_equal 1, in_memory_subscription_count
    end
  end

  describe "updates" do
    it "updates with `object` by default"
    it "updates with the returned value"
    it "skips the update if `:no_update` is returned"
    it "unsubscribes if a `loads:` argument is not found"
    it "unsubscribes if #authorized? fails"
  end

  describe "skipping some updates" do
    it "can broadcast to a subset of subscribers"
  end
end
