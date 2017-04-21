# frozen_string_literal: true
require "spec_helper"

class InMemoryBackend
  # Store API
  class Database
    def initialize
      @queries = {}
      @subscriptions = Hash.new { |h, k| h[k] = [] }
    end

    def set(query, events)
      @queries[query.context[:socket]] = query
      events.each do |ev|
        # The `context` is functioning as subscription data.
        # IRL you'd have some other model that persisted the subscription
        @subscriptions[ev.key] << ev.context
      end
    end

    def get(channel)
      query = @queries[channel]
      {
        query_string: query.query_string,
        operation_name: query.operation_name,
        variables: query.provided_variables,
        context: {},
        transport: :socket,
      }
    end

    def each_channel(key)
      @subscriptions[key].each do |ctx|
        yield(ctx[:socket])
      end
    end

    def delete(channel)
      query = @queries.delete(channel)
      if query
        @subscriptions.each do |key, contexts|
          contexts.delete(query.context)
        end
      end
    end

    # Just for testing:
    def size
      @subscriptions.size
    end
  end

  class Socket
    # Transport API:
    def self.deliver(channel, result, ctx)
      open(channel).deliveries << result
    end

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
  end

  class Queue
    class << self
      def pushes
        @pushes ||= []
      end

      def clear
        pushes.clear
      end

      def enqueue(schema, channel, event_key, object)
        pushes << channel
        schema.subscriber.process(channel, event_key, object)
      end
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
    InMemoryBackend::Queue.clear
  end

  let(:root_object) {
    OpenStruct.new(
      payload: InMemoryBackend::Payload.new,
    )
  }
  let(:database) { InMemoryBackend::Database.new }
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
    end

    query_type = subscription_type.redefine(name: "Query")
    db = database
    GraphQL::Schema.define do
      query(query_type)
      subscription(subscription_type)
      use GraphQL::Subscriptions,
        store: db,
        queue: InMemoryBackend::Queue,
        transports: {
          socket: InMemoryBackend::Socket
        }
    end
  }

  describe "pushing updates" do
    it "sends updated data" do
      query_str = <<-GRAPHQL
        subscription ($id: ID!){
          firstPayload: payload(id: $id) { str, int }
          otherPayload: payload(id: "900") { int }
        }
      GRAPHQL

      # Initial subscriptions
      res_1 = schema.execute(query_str, context: { socket: "1" }, variables: { "id" => "100" }, root_value: root_object)
      res_2 = schema.execute(query_str, context: { socket: "2" }, variables: { "id" => "200" }, root_value: root_object)

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
      assert_equal({"str" => "Update", "int" => 1}, socket_1.deliveries[0]["data"]["firstPayload"])
      assert_equal({"str" => "Update", "int" => 2}, socket_2.deliveries[0]["data"]["firstPayload"])
      assert_equal({"str" => "Update", "int" => 3}, socket_1.deliveries[1]["data"]["firstPayload"])
    end
  end

  describe "subscribing" do
    it "doesn't call the subscriber for invalid queries" do
      query_str = <<-GRAPHQL
        subscription ($id: ID){
          payload(id: $id) { str, int }
        }
      GRAPHQL

      res = schema.execute(query_str, context: { socket: "1" }, variables: { "id" => "100" }, root_value: root_object)
      assert_equal true, res.key?("errors")
      assert_equal 0, database.size
    end
  end

  describe "trigger" do
    it "uses the provided queue" do
      query_str = <<-GRAPHQL
        subscription ($id: ID!){
          payload(id: $id) { str, int }
        }
      GRAPHQL

      schema.execute(query_str, context: { socket: "1" }, variables: { "id" => "8" }, root_value: root_object)
      schema.subscriber.trigger("payload", { "id" => "8"}, root_object.payload)
      assert_equal ["1"], InMemoryBackend::Queue.pushes
    end

    it "pushes errors" do
      query_str = <<-GRAPHQL
        subscription ($id: ID!){
          payload(id: $id) { str, int }
        }
      GRAPHQL

      schema.execute(query_str, context: { socket: "1" }, variables: { "id" => "8" }, root_value: root_object)
      schema.subscriber.trigger("payload", { "id" => "8"}, OpenStruct.new(str: nil, int: nil))
      socket = InMemoryBackend::Socket.open("1")
      delivery = socket.deliveries.first
      assert_equal nil, delivery.fetch("data")
      assert_equal 1, delivery["errors"].length
    end

    it "coerces args somehow?"
    it "handles errors during trigger somehow?"
  end
end
