# frozen_string_literal: true
require "spec_helper"

if defined?(ActionCable)
  class GraphqlChannel < ActionCable::Channel::Base
    def subscribed
      @subscription_ids = []
    end

    def execute(data)
      query = data["query"]
      variables = data["variables"] || {}
      operation_name = data["operationName"]
      context = {
        # Make sure the channel is in the context
        channel: self,
      }

      result = Dummy::Schema.execute({
        query: query,
        context: context,
        variables: variables,
        operation_name: operation_name
      })

      payload = {
        result: result.to_h,
        more: result.subscription?,
      }

      # Track the subscription here so we can remove it
      # on unsubscribe.
      if result.context[:subscription_id]
        @subscription_ids << result.context[:subscription_id]
      end

      transmit(payload)
    end

    def unsubscribed
      @subscription_ids.each { |sid|
        Dummy::Schema.subscriptions.delete_subscription(sid)
      }
    end
  end

  describe GraphQL::Subscriptions::ActionCableSubscriptions do
    let(:channel) { GraphqlChannel.new(connection, {}) }
    let(:connection) { ActionCable::TestConnection.new }

    it "serves queries" do
      channel.perform_action({
        "action" => "execute",
        "query" => "{ __typename }",
      })

      assert_equal 1, connection.transmissions.size
      message = connection.transmissions.first[:message]
      assert_equal "Query", message[:result]["data"]["__typename"]
      assert_equal false, message[:more]
    end

    focus
    it "serves subscriptions" do

    end

    it "uses global ids to pass around objects"
  end
end
