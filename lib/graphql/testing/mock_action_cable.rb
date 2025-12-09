# frozen_string_literal: true
module GraphQL
  module Testing
    # A stub implementation of ActionCable.
    # Any methods to support the mock backend have `mock` in the name.
    #
    # @example Configuring your schema to use MockActionCable in the test environment
    #   class MySchema < GraphQL::Schema
    #     # Use MockActionCable in test:
    #     use GraphQL::Subscriptions::ActionCableSubscriptions,
    #       action_cable: Rails.env.test? ? GraphQL::Testing::MockActionCable : ActionCable
    #   end
    #
    # @example Clearing old data before each test
    #   setup do
    #     GraphQL::Testing::MockActionCable.clear_mocks
    #   end
    #
    # @example Using MockActionCable in a test case
    #   # Create a channel to use in the test, pass it to GraphQL
    #   mock_channel = GraphQL::Testing::MockActionCable.get_mock_channel
    #   ActionCableTestSchema.execute("subscription { newsFlash { text } }", context: { channel: mock_channel })
    #
    #   # Trigger a subscription update
    #   ActionCableTestSchema.subscriptions.trigger(:news_flash, {}, {text: "After yesterday's rain, someone stopped on Rio Road to help a box turtle across five lanes of traffic"})
    #
    #   # Check messages on the channel
    #   expected_msg = {
    #     result: {
    #       "data" => {
    #         "newsFlash" => {
    #           "text" => "After yesterday's rain, someone stopped on Rio Road to help a box turtle across five lanes of traffic"
    #         }
    #       }
    #     },
    #     more: true,
    #   }
    #   assert_equal [expected_msg], mock_channel.mock_broadcasted_messages
    #
    class MockActionCable
      class MockChannel
        def initialize
          @mock_broadcasted_messages = []
        end

        # @return [Array<Hash>] Payloads "sent" to this channel by GraphQL-Ruby
        attr_reader :mock_broadcasted_messages

        # Called by ActionCableSubscriptions. Implements a Rails API.
        def stream_from(stream_name, coder: nil, &block)
          # Rails uses `coder`, we don't
          block ||= ->(msg) { @mock_broadcasted_messages << msg }
          MockActionCable.mock_stream_for(stream_name).add_mock_channel(self, block)
        end
      end

      # Used by mock code
      # @api private
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
        # Call this before each test run to make sure that MockActionCable's data is empty
        def clear_mocks
          @mock_streams = {}
        end

        # Implements Rails API
        def server
          self
        end

        # Implements Rails API
        def broadcast(stream_name, message)
          stream = @mock_streams[stream_name]
          stream && stream.mock_broadcast(message)
        end

        # Used by mock code
        def mock_stream_for(stream_name)
          @mock_streams[stream_name] ||= MockStream.new
        end

        # Use this as `context[:channel]` to simulate an ActionCable channel
        #
        # @return [GraphQL::Testing::MockActionCable::MockChannel]
        def get_mock_channel
          MockChannel.new
        end

        # @return [Array<String>] Streams that currently have subscribers
        def mock_stream_names
          @mock_streams.keys
        end
      end
    end
  end
end
