# frozen_string_literal: true
require "spec_helper"

class InMemoryBackend
  class Subscriptions < GraphQL::Subscriptions
    attr_reader :deliveries, :pushes, :extra

    def initialize(schema:, extra:)
      super
      @extra = extra
      @queries = {}
      @subscriptions = Hash.new { |h, k| h[k] = [] }
      @deliveries = Hash.new { |h, k| h[k] = [] }
      @pushes = []
    end

    def write_subscription(query, events)
      @queries[query.context[:socket]] = query
      events.each do |ev|
        # The `context` is functioning as subscription data.
        # IRL you'd have some other model that persisted the subscription
        @subscriptions[ev.topic] << ev.context
      end
    end

    def each_subscription_id(event)
      @subscriptions[event.topic].each do |ctx|
        yield(ctx[:socket])
      end
    end

    def read_subscription(channel)
      query = @queries[channel]
      {
        query_string: query.query_string,
        operation_name: query.operation_name,
        variables: query.provided_variables,
        context: { me: query.context[:me] },
        transport: :socket,
      }
    end

    def delete_subscription(channel)
      query = @queries.delete(channel)
      if query
        @subscriptions.each do |key, contexts|
          contexts.delete(query.context)
        end
      end
    end

    def deliver(channel, result)
      @deliveries[channel] << result
    end

    def execute(channel, event, object)
      @pushes << channel
      super
    end

    # Just for testing:
    def reset
      @queries.clear
      @subscriptions.clear
      @deliveries.clear
      @pushes.clear
    end

    def size
      @subscriptions.size
    end

    def subscriptions
      @subscriptions
    end
  end
  # Just a random stateful object for tracking what happens:
  class SubscriptionPayload
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

class ClassBasedInMemoryBackend < InMemoryBackend
  class Payload < GraphQL::Schema::Object
    field :str, String, null: false
    field :int, Integer, null: false
  end

  class PayloadType < GraphQL::Schema::Enum
    graphql_name "PayloadType"
    # Arbitrary "kinds" of payloads which may be
    # subscribed to separately
    value "ONE"
    value "TWO"
  end

  class StreamInput < GraphQL::Schema::InputObject
    argument :user_id, ID, required: true
    argument :type, PayloadType, required: false, default_value: "ONE"
  end

  class Subscription < GraphQL::Schema::Object
    field :payload, Payload, null: false do
      argument :id, ID, required: true
    end

    def payload(id:)
      object
    end

    field :event, Payload, null: true do
      argument :stream, StreamInput, required: false
    end

    def event(stream: nil)
      object
    end

    field :my_event, Payload, null: true, subscription_scope: :me do
      argument :type, PayloadType, required: false
    end

    def my_event(type: nil)
      object
    end

    field :failed_event, Payload, null: false, resolve: ->(o, a, c) { raise GraphQL::ExecutionError.new("unauthorized") }  do
      argument :id, ID, required: true
    end
  end

  class Query < GraphQL::Schema::Object
    field :dummy, Integer, null: true
  end

  class Schema < GraphQL::Schema
    query(Query)
    subscription(Subscription)
    use InMemoryBackend::Subscriptions, extra: 123
  end
end

class FromDefinitionInMemoryBackend < InMemoryBackend
  SchemaDefinition = <<-GRAPHQL
  type Subscription {
    payload(id: ID!): Payload!
    event(stream: StreamInput): Payload
    myEvent(type: PayloadType): Payload
    failedEvent(id: ID!): Payload!
  }

  type Payload {
    str: String!
    int: Int!
  }

  input StreamInput {
    userId: ID!
    type: PayloadType = ONE
  }

  # Arbitrary "kinds" of payloads which may be
  # subscribed to separately
  enum PayloadType {
    ONE
    TWO
  }

  type Query {
    dummy: Int
  }
  GRAPHQL

  Resolvers = {
    "Subscription" => {
      "payload" => ->(o,a,c) { o },
      "myEvent" => ->(o,a,c) { o },
      "event" => ->(o,a,c) { o },
      "failedEvent" => ->(o,a,c) { raise GraphQL::ExecutionError.new("unauthorized") },
    },
  }
  Schema = GraphQL::Schema.from_definition(SchemaDefinition, default_resolve: Resolvers).redefine do
    use InMemoryBackend::Subscriptions,
        extra: 123
  end

  # TODO don't hack this (no way to add metadata from IDL parser right now)
  Schema.get_field("Subscription", "myEvent").subscription_scope = :me
end

if defined?(GlobalID)
  GlobalID.app = "graphql-ruby-test"

  class GlobalIDUser
    include GlobalID::Identification

    attr_reader :id

    def initialize(id)
      @id = id
    end
  end

  class ToParamUser
    def initialize(id)
      @id = id
    end

    def to_param
      @id
    end
  end
end

describe GraphQL::Subscriptions do
  before do
    schema.subscriptions.reset
  end

  [ClassBasedInMemoryBackend, FromDefinitionInMemoryBackend].each do |in_memory_backend_class|
    describe "using #{in_memory_backend_class}" do
      let(:root_object) {
        OpenStruct.new(
          payload: in_memory_backend_class::SubscriptionPayload.new,
          )
      }

      let(:schema) { in_memory_backend_class::Schema }
      let(:implementation) { schema.subscriptions }
      let(:deliveries) { implementation.deliveries }
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
          assert_equal [], deliveries["1"]
          assert_equal [], deliveries["2"]

          # Application stuff happens.
          # The application signals graphql via `subscriptions.trigger`:
          schema.subscriptions.trigger(:payload, {"id" => "100"}, root_object.payload)
          schema.subscriptions.trigger("payload", {"id" => "200"}, root_object.payload)
          # Symobls are OK too
          schema.subscriptions.trigger(:payload, {:id => "100"}, root_object.payload)
          schema.subscriptions.trigger("payload", {"id" => "300"}, nil)

          # Let's see what GraphQL sent over the wire:
          assert_equal({"str" => "Update", "int" => 1}, deliveries["1"][0]["data"]["firstPayload"])
          assert_equal({"str" => "Update", "int" => 2}, deliveries["2"][0]["data"]["firstPayload"])
          assert_equal({"str" => "Update", "int" => 3}, deliveries["1"][1]["data"]["firstPayload"])
        end
      end

      describe "subscribing" do
        it "doesn't call the subscriptions for invalid queries" do
          query_str = <<-GRAPHQL
        subscription ($id: ID){
          payload(id: $id) { str, int }
        }
          GRAPHQL

          res = schema.execute(query_str, context: { socket: "1" }, variables: { "id" => "100" }, root_value: root_object)
          assert_equal true, res.key?("errors")
          assert_equal 0, implementation.size
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
          schema.subscriptions.trigger("payload", { "id" => "8"}, root_object.payload)
          assert_equal ["1"], implementation.pushes
        end

        it "pushes errors" do
          query_str = <<-GRAPHQL
        subscription ($id: ID!){
          payload(id: $id) { str, int }
        }
          GRAPHQL

          schema.execute(query_str, context: { socket: "1" }, variables: { "id" => "8" }, root_value: root_object)
          schema.subscriptions.trigger("payload", { "id" => "8"}, OpenStruct.new(str: nil, int: nil))
          delivery = deliveries["1"].first
          assert_nil delivery.fetch("data")
          assert_equal 1, delivery["errors"].length
        end

        it "coerces args" do
          query_str = <<-GRAPHQL
        subscription($type: PayloadType) {
          e1: event(stream: { userId: "3", type: $type }) { int }
        }
          GRAPHQL

          # Subscribe with explicit `TYPE`
          schema.execute(query_str, context: { socket: "1" }, variables: { "type" => "ONE" }, root_value: root_object)
          # Subscribe with default `TYPE`
          schema.execute(query_str, context: { socket: "2" }, root_value: root_object)
          # Subscribe with non-matching `TYPE`
          schema.execute(query_str, context: { socket: "3" }, variables: { "type" => "TWO" }, root_value: root_object)
          # Subscribe with explicit null
          schema.execute(query_str, context: { socket: "4" }, variables: { "type" => nil }, root_value: root_object)

          # Trigger the subscription with coerceable args, different orders:
          schema.subscriptions.trigger("event", { "stream" => {"userId" => 3, "type" => "ONE"} }, OpenStruct.new(str: "", int: 1))
          schema.subscriptions.trigger("event", { "stream" => {"type" => "ONE", "userId" => "3"} }, OpenStruct.new(str: "", int: 2))
          # This is a non-trigger
          schema.subscriptions.trigger("event", { "stream" => {"userId" => "3", "type" => "TWO"} }, OpenStruct.new(str: "", int: 3))
          # These get default value of ONE (underscored / symbols are ok)
          schema.subscriptions.trigger("event", { stream: { user_id: "3"} }, OpenStruct.new(str: "", int: 4))
          # Trigger with null updates subscriptionss to null
          schema.subscriptions.trigger("event", { "stream" => {"userId" => 3, "type" => nil} }, OpenStruct.new(str: "", int: 5))

          assert_equal [1,2,4], deliveries["1"].map { |d| d["data"]["e1"]["int"] }

          # Same as socket_1
          assert_equal [1,2,4], deliveries["2"].map { |d| d["data"]["e1"]["int"] }

          # Received the "non-trigger"
          assert_equal [3], deliveries["3"].map { |d| d["data"]["e1"]["int"] }

          # Received the trigger with null
          assert_equal [5], deliveries["4"].map { |d| d["data"]["e1"]["int"] }
        end

        it "allows context-scoped subscriptions" do
          query_str = <<-GRAPHQL
        subscription($type: PayloadType) {
          myEvent(type: $type) { int }
        }
          GRAPHQL

          # Subscriptions for user 1
          schema.execute(query_str, context: { socket: "1", me: "1" }, variables: { "type" => "ONE" }, root_value: root_object)
          schema.execute(query_str, context: { socket: "2", me: "1" }, variables: { "type" => "TWO" }, root_value: root_object)
          # Subscription for user 2
          schema.execute(query_str, context: { socket: "3", me: "2" }, variables: { "type" => "ONE" }, root_value: root_object)

          schema.subscriptions.trigger("myEvent", { "type" => "ONE" }, OpenStruct.new(str: "", int: 1), scope: "1")
          schema.subscriptions.trigger("myEvent", { "type" => "TWO" }, OpenStruct.new(str: "", int: 2), scope: "1")
          schema.subscriptions.trigger("myEvent", { "type" => "ONE" }, OpenStruct.new(str: "", int: 3), scope: "2")

          # Delivered to user 1
          assert_equal [1], deliveries["1"].map { |d| d["data"]["myEvent"]["int"] }
          assert_equal [2], deliveries["2"].map { |d| d["data"]["myEvent"]["int"] }
          # Delivered to user 2
          assert_equal [3], deliveries["3"].map { |d| d["data"]["myEvent"]["int"] }
        end

        if defined?(GlobalID)
          it "allows complex object subscription scopes" do
            query_str = <<-GRAPHQL
          subscription($type: PayloadType) {
            myEvent(type: $type) { int }
          }
            GRAPHQL

            # Global ID Backed User
            schema.execute(query_str, context: { socket: "1", me: GlobalIDUser.new(1) }, variables: { "type" => "ONE" }, root_value: root_object)
            schema.execute(query_str, context: { socket: "2", me: GlobalIDUser.new(1) }, variables: { "type" => "TWO" }, root_value: root_object)
            # ToParam Backed User
            schema.execute(query_str, context: { socket: "3", me: ToParamUser.new(2) }, variables: { "type" => "ONE" }, root_value: root_object)
            # Array of Objects
            schema.execute(query_str, context: { socket: "4", me: [GlobalIDUser.new(4), ToParamUser.new(5)] }, variables: { "type" => "ONE" }, root_value: root_object)

            schema.subscriptions.trigger("myEvent", { "type" => "ONE" }, OpenStruct.new(str: "", int: 1), scope: GlobalIDUser.new(1))
            schema.subscriptions.trigger("myEvent", { "type" => "TWO" }, OpenStruct.new(str: "", int: 2), scope: GlobalIDUser.new(1))
            schema.subscriptions.trigger("myEvent", { "type" => "ONE" }, OpenStruct.new(str: "", int: 3), scope: ToParamUser.new(2))
            schema.subscriptions.trigger("myEvent", { "type" => "ONE" }, OpenStruct.new(str: "", int: 4), scope: [GlobalIDUser.new(4), ToParamUser.new(5)])

            # Delivered to GlobalIDUser
            assert_equal [1], deliveries["1"].map { |d| d["data"]["myEvent"]["int"] }
            assert_equal [2], deliveries["2"].map { |d| d["data"]["myEvent"]["int"] }
            # Delivered to ToParamUser
            assert_equal [3], deliveries["3"].map { |d| d["data"]["myEvent"]["int"] }
            # Delivered to Array of GlobalIDUser and ToParamUser
            assert_equal [4], deliveries["4"].map { |d| d["data"]["myEvent"]["int"] }
          end
        end

        describe "errors" do
          class ErrorPayload
            def int
              raise "Boom!"
            end

            def str
              raise GraphQL::ExecutionError.new("This is handled")
            end
          end

          it "avoid subscription on resolver error" do
            res = schema.execute(<<-GRAPHQL, context: { socket: "1" }, variables: { "id" => "100" })
          subscription ($id: ID!){
            failedEvent(id: $id) { str, int }
          }
            GRAPHQL

            assert_equal nil, res["data"]
            assert_equal "unauthorized", res["errors"][0]["message"]

            # this is to make sure nothing actually got subscribed.. but I don't have any idea better than checking its instance variable
            assert_equal 0, schema.subscriptions.instance_variable_get(:@subscriptions).size
          end

          it "lets unhandled errors crash" do
            query_str = <<-GRAPHQL
          subscription($type: PayloadType) {
            myEvent(type: $type) { int }
          }
            GRAPHQL

            schema.execute(query_str, context: { socket: "1", me: "1" }, variables: { "type" => "ONE" }, root_value: root_object)
            err = assert_raises(RuntimeError) {
              schema.subscriptions.trigger("myEvent", { "type" => "ONE" }, ErrorPayload.new, scope: "1")
            }
            assert_equal "Boom!", err.message
          end
        end

        it "sends query errors to the subscriptions" do
          query_str = <<-GRAPHQL
        subscription($type: PayloadType) {
          myEvent(type: $type) { str }
        }
          GRAPHQL

          schema.execute(query_str, context: { socket: "1", me: "1" }, variables: { "type" => "ONE" }, root_value: root_object)
          schema.subscriptions.trigger("myEvent", { "type" => "ONE" }, ErrorPayload.new, scope: "1")
          res = deliveries["1"].first
          assert_equal "This is handled", res["errors"][0]["message"]
        end
      end

      describe "implementation" do
        it "is initialized with keywords" do
          assert_equal 123, schema.subscriptions.extra
        end
      end

      describe "#build_id" do
        it "returns a unique ID string" do
          assert_instance_of String, schema.subscriptions.build_id
          refute_equal schema.subscriptions.build_id, schema.subscriptions.build_id
        end
      end

      describe ".trigger" do
        it "raises when event name is not found" do
          err = assert_raises(GraphQL::Subscriptions::InvalidTriggerError) do
            schema.subscriptions.trigger(:nonsense_field, {}, nil)
          end

          assert_includes err.message, "trigger: nonsense_field"
          assert_includes err.message, "Subscription.nonsenseField"
        end

        it "raises when argument is not found" do
          err = assert_raises(GraphQL::Subscriptions::InvalidTriggerError) do
            schema.subscriptions.trigger(:event, { scream: {"userId" => "😱"} }, nil)
          end

          assert_includes err.message, "arguments: scream"
          assert_includes err.message, "arguments of Subscription.event"

          err = assert_raises(GraphQL::Subscriptions::InvalidTriggerError) do
            schema.subscriptions.trigger(:event, { stream: { user_id_number: "😱"} }, nil)
          end

          assert_includes err.message, "arguments: user_id_number"
          assert_includes err.message, "arguments of StreamInput"
        end
      end
    end
  end
end
