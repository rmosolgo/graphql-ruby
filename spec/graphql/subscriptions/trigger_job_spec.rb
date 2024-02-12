# frozen_string_literal: true
require "spec_helper"

describe "GraphQL::Subscriptions::TriggerJob" do
  before do
    skip "Requires Rails" unless testing_rails?
    TriggerJobSchema.subscriptions.reset
  end

  if defined?(ActiveJob)
    include ActiveJob::TestHelper
    ActiveJob::Base.logger = Logger.new(IO::NULL)
  end

  class TriggerJobSchema < GraphQL::Schema
    class InMemorySubscriptions < GraphQL::Subscriptions
      attr_reader :write_subscription_events, :execute_all_events

      def initialize(...)
        super
        reset
      end

      def write_subscription(_query, events)
        @write_subscription_events.concat(events)
      end

      def execute_all(event, _object)
        @execute_all_events.push(event)
      end

      def reset
        @write_subscription_events = []
        @execute_all_events = []
      end
    end

    class Subscription < GraphQL::Schema::Object
      class Update < GraphQL::Schema::Subscription
        field :news, String

        def resolve
          object
          {
            news: (object && object[:news]) ? object[:news] : "Hello World"
          }
        end
      end

      field :update, subscription: Update
    end
    subscription Subscription
    use InMemorySubscriptions
  end

  it "Creates a custom ActiveJob::Base subclass" do
    assert_equal TriggerJobSchema::SubscriptionsTriggerJob, TriggerJobSchema.subscriptions.trigger_job
    assert_equal GraphQL::Subscriptions::TriggerJob, TriggerJobSchema::SubscriptionsTriggerJob.superclass
    assert_equal ActiveJob::Base, TriggerJobSchema::SubscriptionsTriggerJob.superclass.superclass
  end

  it "runs .trigger in the background" do
    res = TriggerJobSchema.execute("subscription { update { news } }")
    assert_equal 1, TriggerJobSchema.subscriptions.write_subscription_events.size
    assert_equal 0, TriggerJobSchema.subscriptions.execute_all_events.size
    perform_enqueued_jobs do
      TriggerJobSchema.subscriptions.trigger_later(:update, {}, { news: "Expect a week of sunshine" })
    end
    assert_equal 1, TriggerJobSchema.subscriptions.execute_all_events.size

  end
end
