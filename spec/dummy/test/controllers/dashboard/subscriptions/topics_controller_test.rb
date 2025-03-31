# frozen_string_literal: true
require "test_helper"
require "ostruct" # TODO use a real class in RedisBackend
class DashboardSubscriptionsTopicsControllerTest < ActionDispatch::IntegrationTest
  def test_it_checks_installed
    get graphql_dashboard.subscriptions_topics_path, params: { schema: GraphQL::Schema }
    assert_includes response.body, "GraphQL-Pro Subscriptions aren't installed on this schema yet."
  end

  def test_it_renders_empty_state_and_not_found_states
    get graphql_dashboard.subscriptions_topics_path
    assert_includes response.body, "There aren't any subscriptions right now."
    get graphql_dashboard.subscriptions_topic_path(":something:")
    assert_includes response.body, ":something:"
    assert_includes response.body, "Last triggered: none"
    assert_includes response.body, "0 Subscriptions"
    get graphql_dashboard.subscriptions_subscription_path("abcd-efg")
    assert_includes response.body, "abcd-efg"
    assert_includes response.body, "This subscription was not found or is no longer active."
  end

  def test_it_lists_topics_and_shows_detail
    DummySchema.subscriptions.clear
    res1 = DummySchema.execute("subscription { message(channel: \"cats\") }")
    res2 = DummySchema.execute("subscription { message(channel: \"dogs\") }")
    DummySchema.subscriptions.trigger(:message, { channel: "dogs"}, "Woof!")
    get graphql_dashboard.subscriptions_topics_path
    assert_includes response.body, ":message:channel:cats"
    assert_includes response.body, ":message:channel:dogs"
    assert_includes response.body, Time.now.strftime("%Y-%m-%d %H:%M:%S")

    get graphql_dashboard.subscriptions_topic_path(":message:channel:dogs")
    assert_includes response.body, res2.context[:subscription_id]
    assert_includes response.body, Time.now.strftime("%Y-%m-%d %H:%M:%S")

    get graphql_dashboard.subscriptions_subscription_path(res2.context[:subscription_id])
    assert_includes response.body, res2.context[:subscription_id]
    assert_includes response.body, CGI::escapeHTML('subscription { message(channel: "dogs") }')

    post graphql_dashboard.subscriptions_clear_all_path
    get graphql_dashboard.subscriptions_topics_path
    refute_includes response.body, ":message:"
  ensure
    DummySchema.subscriptions.clear
  end
end
