# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Subscriptions::Event do
  class EventSchema < GraphQL::Schema

    class Query < GraphQL::Schema::Object
    end

    class JsonSubscription < GraphQL::Schema::Subscription
      argument :some_json, GraphQL::Types::JSON, required: false

      field :text, String, null: false
    end

    class Subscription < GraphQL::Schema::Object
      field :json_subscription, subscription: JsonSubscription
    end

    query(Query)
    subscription(Subscription)
  end

  it "should serialize a JSON argument into the topic name" do
    field = EventSchema.subscription.fields["jsonSubscription"]
    event = GraphQL::Subscriptions::Event.new(name: "test", arguments: { "someJson" => { "b" => 1, "a" => 0 } }, field: field, context: nil, scope: nil)
    assert_equal event.topic, %Q{:jsonSubscription:someJson:{"b":1,"a":0}}
  end
end
