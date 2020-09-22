# frozen_string_literal: true
require "spec_helper"


describe GraphQL::Subscriptions::ActionCableSubscriptions do
  # A stub implementation of ActionCable.
  # Any methods to support the mock backend have `mock` in the name.
  class MockActionCable
    class MockChannel
      def initialize
        @mock_broadcasted_messages = []
      end

      attr_reader :mock_broadcasted_messages

      def stream_from(stream_name, coder: nil, &block)
        # Rails uses `coder`, we don't
        block ||= ->(msg) { @mock_broadcasted_messages << msg }
        MockActionCable.mock_stream_for(stream_name).add_mock_channel(self, block)
      end
    end

    class MockStream
      def initialize
        @mock_channels = {}
      end

      def add_mock_channel(channel, handler)
        @mock_channels[channel] = handler
      end

      def mock_broadcast(message)
        @mock_channels.each do |channel, handler|
          handler && handler.call(message)
        end
      end
    end

    class << self
      def clear_mocks
        @mock_streams = {}
      end

      def server
        self
      end

      def broadcast(stream_name, message)
        stream = @mock_streams[stream_name]
        stream && stream.mock_broadcast(message)
      end

      def mock_stream_for(stream_name)
        @mock_streams[stream_name] ||= MockStream.new
      end

      def get_mock_channel
        MockChannel.new
      end

      def mock_stream_names
        @mock_streams.keys
      end
    end
  end

  class ActionCableTestSchema < GraphQL::Schema
    class Query < GraphQL::Schema::Object
      field :int, Integer, null: true
    end

    class NewsFlash < GraphQL::Schema::Subscription
      field :text, String, null: false
    end

    class Subscription < GraphQL::Schema::Object
      field :news_flash, subscription: NewsFlash
    end

    query(Query)
    subscription(Subscription)
    use GraphQL::Execution::Interpreter
    use GraphQL::Analysis::AST
    use GraphQL::Subscriptions::ActionCableSubscriptions,
      action_cable: MockActionCable,
      action_cable_coder: JSON
  end

  class NamespacedActionCableTestSchema < GraphQL::Schema
    query(ActionCableTestSchema::Query)
    subscription(ActionCableTestSchema::Subscription)
    use GraphQL::Execution::Interpreter
    use GraphQL::Analysis::AST
    use GraphQL::Subscriptions::ActionCableSubscriptions,
      namespace: "other:",
      action_cable: MockActionCable,
      action_cable_coder: JSON
  end

  before do
    MockActionCable.clear_mocks
  end

  def subscription_update(data)
    { result: { "data" => data }, more: true }
  end

  it "sends updates over the given `action_cable:`" do
    mock_channel = MockActionCable.get_mock_channel
    ActionCableTestSchema.execute("subscription { newsFlash { text } }", context: { channel: mock_channel })
    ActionCableTestSchema.subscriptions.trigger(:news_flash, {}, {text: "After yesterday's rain, someone stopped on Rio Road to help a box turtle across five lanes of traffic"})
    expected_msg = subscription_update({
      "newsFlash" => {
        "text" => "After yesterday's rain, someone stopped on Rio Road to help a box turtle across five lanes of traffic"
      }
    })
    assert_equal [expected_msg], mock_channel.mock_broadcasted_messages
  end

  it "uses namespace to divide traffic" do
    mock_channel_1 = MockActionCable.get_mock_channel
    ctx_1 = { channel: mock_channel_1 }
    ActionCableTestSchema.execute("subscription { newsFlash { text } }", context: ctx_1)

    mock_channel_2 = MockActionCable.get_mock_channel
    ctx_2 = { channel: mock_channel_2 }
    NamespacedActionCableTestSchema.execute("subscription { newsFlash { text } }", context: ctx_2)

    ActionCableTestSchema.subscriptions.trigger(:news_flash, {}, {text: "Neighbor shares bumper crop of summer squash with widow next door"})
    NamespacedActionCableTestSchema.subscriptions.trigger(:news_flash, {}, {text: "Sunrise enjoyed over a cup of coffee"})

    expected_msg_1 = subscription_update({
      "newsFlash" => {
        "text" => "Neighbor shares bumper crop of summer squash with widow next door"
      }
    })

    expected_msg_2 = subscription_update({
      "newsFlash" => {
        "text" => "Sunrise enjoyed over a cup of coffee"
      }
    })

    assert_equal [expected_msg_1], mock_channel_1.mock_broadcasted_messages
    assert_equal [expected_msg_2], mock_channel_2.mock_broadcasted_messages

    expected_streams = [
      # No namespace
      "graphql-subscription:#{ctx_1[:subscription_id]}",
      "graphql-event::newsFlash:",
      # Namespaced with `other:`
      "graphql-subscription:other:#{ctx_2[:subscription_id]}",
      "graphql-event:other::newsFlash:",
    ]
    assert_equal expected_streams, MockActionCable.mock_stream_names
  end

  it "handles `execute_update` for a missing subscription ID" do
    res = ActionCableTestSchema.subscriptions.execute_update("nonsense-id", {}, {})
    assert_nil res
  end
end
