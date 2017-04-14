# frozen_string_literal: true
require "spec_helper"

class InMemoryBackend
  # Here's the required API for a subscriber:
  class Subscriber
    def initialize(schema:, database:)
      @database = database
      @schema = schema
    end

    def register_query(query)
    end

    def register(obj, args, ctx)
      # The `ctx` is functioning as subscription data.
      # IRL you'd have some other model that persisted the subscription
      @database.add(ctx.field.name, args, ctx)
    end

    def trigger(event, args, object)
      subs = @database.fetch(event, args)
      subs.each { |ctx|
        res = @schema.execute(
          document: ctx.query.document,
          variables: ctx.query.provided_variables,
          subscription_name: event,
          root_value: object,
        )
        # This is like "broadcast"
        socket = Socket.open(ctx[:socket_id])
        socket.write(res)
      }
    end
  end

  # Subscription management database
  class Database
    def subscriptions
      @subscriptions ||= Hash.new { |h, k| h[k] = [] }
    end

    def fetch(field, args)
      subscriptions[key(field, args)]
    end

    def add(field, args, sub)
      subscriptions[key(field, args)] << sub
    end

    private

    def key(field, args)
      "#{field}(#{JSON.dump(args.to_h)})"
    end
  end

  # Pretend its a websocket:
  class Socket
    def self.open(id)
      @sockets[id]
    end

    def self.clear
      @sockets = Hash.new { |h, k| h[k] = self.new }
    end

    attr_reader :deliveries

    def initialize
      @deliveries = []
    end

    def write(response)
      @deliveries << response
    end
  end

  # Just a random stateful object for tracking what happens:
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
  before do
    InMemoryBackend::Socket.clear
  end

  let(:root_object) {
    OpenStruct.new(
      payload: InMemoryBackend::Payload.new,
      otherPayload: InMemoryBackend::Payload.new,
    )
  }
  let(:schema) {
    payload_type = GraphQL::ObjectType.define do
      name "Payload"
      field :str, !types.String
      field :int, !types.Int
    end

    subscription_type = GraphQL::ObjectType.define do
      name "Subscription"
      field :payload, !payload_type do
        argument :id, !types.ID
      end
      field :otherPayload, !payload_type do
        argument :id, !types.ID
      end
    end

    query_type = subscription_type.redefine(name: "Query")

    GraphQL::Schema.define do
      query(query_type)
      subscription(subscription_type)
      use GraphQL::Subscriptions,
        subscriber_class: InMemoryBackend::Subscriber,
        options: {
          database: InMemoryBackend::Database.new,
        }
    end
  }

  describe "pushing updates" do
    it "sends updated data" do
      query_str = <<-GRAPHQL
        subscription ($id: ID!){
          payload(id: $id) { str, int }
          otherPayload(id: "900") { int }
        }
      GRAPHQL

      # Initial subscriptions
      res_1 = schema.execute(query_str, context: { socket_id: "1" }, variables: { "id" => "100" }, root_value: root_object)
      res_2 = schema.execute(query_str, context: { socket_id: "2" }, variables: { "id" => "200" }, root_value: root_object)

      # Initial response is nil, no broadcasts yet
      assert_equal(nil, res_1["data"])
      assert_equal(nil, res_2["data"])
      socket_1 = InMemoryBackend::Socket.open("1")
      socket_2 = InMemoryBackend::Socket.open("2")
      assert_equal [], socket_1.deliveries
      assert_equal [], socket_2.deliveries

      # Application stuff happens.
      # The application signals graphql via `subscriber.trigger`:
      schema.subscriber.trigger("payload", {"id" => "100"}, root_object.payload)
      schema.subscriber.trigger("payload", {"id" => "200"}, root_object.payload)
      schema.subscriber.trigger("payload", {"id" => "100"}, root_object.payload)
      schema.subscriber.trigger("payload", {"id" => "300"}, nil)

      # Let's see what GraphQL sent over the wire:
      assert_equal({"str" => "Update", "int" => 1}, socket_1.deliveries[0]["data"]["payload"])
      assert_equal({"str" => "Update", "int" => 2}, socket_2.deliveries[0]["data"]["payload"])
      assert_equal({"str" => "Update", "int" => 3}, socket_1.deliveries[1]["data"]["payload"])
    end
  end
end
