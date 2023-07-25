# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Tracing::NotificationsTrace do
  module NotificationsTraceTest
    class Query < GraphQL::Schema::Object
      field :int, Integer, null: false

      def int
        1
      end
    end

    class Schema < GraphQL::Schema
      query Query
    end
  end

  describe "Observing" do
    it "dispatchs the event to the notifications engine with suffixed key" do
      dispatched_events = trigger_fake_notifications_tracer(NotificationsTraceTest::Schema).to_h

      assert dispatched_events.length > 0

      expected_event_keys = [
        'execute_multiplex.graphql',
        'analyze_multiplex.graphql',
        'lex.graphql',
        'parse.graphql',
        'validate.graphql',
        'analyze_query.graphql',
        'execute_query.graphql',
        'authorized.graphql',
        'execute_field.graphql',
        'execute_query_lazy.graphql'
      ]

      assert_equal expected_event_keys, dispatched_events.keys

      dispatched_events.each do |event, payload|
        assert event.end_with?(".graphql")
        assert payload.is_a?(Hash)
      end
    end
  end

  def trigger_fake_notifications_tracer(schema)
    dispatched_events = []
    engine = Object.new

    engine.define_singleton_method(:instrument) do |event, payload, &blk|
      dispatched_events << [event, payload]
      blk.call if blk
    end

    schema.trace_with GraphQL::Tracing::NotificationsTrace, engine: engine
    schema.execute "query X { int }"

    dispatched_events
  end
end
