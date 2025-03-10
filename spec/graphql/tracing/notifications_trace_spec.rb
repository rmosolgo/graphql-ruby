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

    class DummyEngine < GraphQL::Tracing::NotificationsTrace::Engine
      class << self
        def dispatched_events
          @dispatched_events ||= []
        end
      end

      def instrument(event, payload = nil)
        self.class.dispatched_events << [event, payload]
        yield
      end
      class Event < GraphQL::Tracing::NotificationsTrace::Engine::Event
        def start; end
        def finish
          DummyEngine.dispatched_events << [@keyword, @payload]
        end
      end
    end

    module OtherTrace
      def execute_query(query:)
        query.context[:other_trace_ran] = true
        super
      end
    end

    class Schema < GraphQL::Schema
      query Query
      trace_with OtherTrace
      trace_with GraphQL::Tracing::NotificationsTrace, engine: DummyEngine, trace_scalars: true
    end
  end

  before do
    NotificationsTraceTest::DummyEngine.dispatched_events.clear
  end


  describe "Observing" do
    it "dispatches the event to the notifications engine with a keyword" do
      NotificationsTraceTest::Schema.execute "query X { int }"
      dispatched_events = NotificationsTraceTest::DummyEngine.dispatched_events.to_h
      expected_event_keys = [
        :execute,
        (USING_C_PARSER ? :lex : nil),
        :parse,
        :validate,
        :analyze,
        :authorized,
        :execute_field
      ].compact

      assert_equal expected_event_keys, dispatched_events.keys
    end

    it "works with other tracers" do
      res = NotificationsTraceTest::Schema.execute "query X { int }"
      assert res.context[:other_trace_ran]
    end
  end
end
