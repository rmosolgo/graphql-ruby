# frozen_string_literal: true
require "spec_helper"

class InMemorySubscriber
  class << self
    def subscriptions
      @subscriptions ||= Hash.new { |h, k| h[k] = [] }
    end

    def clear
      @subscriptions = nil
    end

    def trigger(field, args)
      k = key(field, args)
      subs = subscriptions[k]
      subs.each(&:trigger)
    end

    def key(field, args)
      "#{field}(#{JSON.dump(args.to_h)})"
    end
  end

  def register(obj, args, ctx)
    sub_key = self.class.key(ctx.field.name, args)
    subscription = Subscription.new(ctx)
    self.class.subscriptions[sub_key] << subscription
  end

  class Subscription
    attr_reader :ctx

    def initialize(ctx)
      @ctx = ctx
    end

    def trigger
      payloads = ctx[:payloads]
      schema = ctx.schema
      res = schema.execute(
        document: ctx.query.document,
        context: {payloads: payloads, resubscribe: false},
        root_value: ctx[:root],
      )
      # This is like "broadcast"
      payloads.push(res)
    end
  end

  class Payload
    attr_reader :str

    def initialize
      @str = "Update"
      @counter = 0
    end

    def int
      @counter += 1
    end
  end
end


describe GraphQL::Subscriptions do
  let(:root_object) { OpenStruct.new(payload: InMemorySubscriber::Payload.new) }
  let(:schema) {
    payload_type = GraphQL::ObjectType.define do
      name "Payload"
      field :str, !types.String
      field :int, !types.Int
    end

    subscription_type = GraphQL::ObjectType.define do
      name "Subscription"
      field :payload, payload_type do
        argument :id, !types.ID
      end
    end

    query_type = subscription_type.redefine(name: "Query")

    GraphQL::Schema.define do
      query(query_type)
      subscription(subscription_type)
      use(GraphQL::Subscriptions, subscriber: InMemorySubscriber)
    end
  }

  describe "pushing updates" do
    before do
      InMemorySubscriber.clear
    end

    it "sends updated data" do
      query_str = <<-GRAPHQL
        subscription {
          payload(id: "1") { str, int }
        }
      GRAPHQL

      payloads = []
      res = schema.execute(query_str, context: { payloads: payloads, root: root_object }, root_value: root_object)

      # Initial Result:
      assert_equal [], payloads
      assert_equal({"str" => "Update", "int" => 1}, res["data"]["payload"])

      # Hit:
      InMemorySubscriber.trigger("payload", id: "1")
      InMemorySubscriber.trigger("payload", id: "1")
      # Miss:
      InMemorySubscriber.trigger("payload", id: "2")

      assert_equal({"str" => "Update", "int" => 2}, payloads[0]["data"]["payload"])
      assert_equal({"str" => "Update", "int" => 3}, payloads[1]["data"]["payload"])
    end
  end
end
