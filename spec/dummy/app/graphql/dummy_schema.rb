# frozen_string_literal: true

begin
  require "graphql-pro"
rescue LoadError => err
  puts "Skipping GraphQL::Pro: #{err.message}"
end
class DummySchema < GraphQL::Schema
  class Query < GraphQL::Schema::Object
    field :str, String, fallback_value: "hello"
  end
  query(Query)

  class Subscription < GraphQL::Schema::Object
    field :message, String do
      argument :channel, String
    end
  end
  subscription(Subscription)

  use GraphQL::Tracing::DetailedTrace, memory: true

  if defined?(GraphQL::Pro)
    DB_NUMBER = Rails.env.test? ? 1 : 0
    use GraphQL::Pro::OperationStore, redis: Redis.new(db: DB_NUMBER)
    use GraphQL::Pro::PusherSubscriptions, redis: Redis.new(db: DummySchema::DB_NUMBER), pusher: MockPusher.new
  end

  def self.detailed_trace?(query)
    query.context[:profile]
  end
end

# To preview subscription data in the dashboard:
# DummySchema.subscriptions.clear
# res1 = DummySchema.execute("subscription { message(channel: \"cats\") }")
# res2 = DummySchema.execute("subscription { message(channel: \"dogs\") }")
# DummySchema.subscriptions.trigger(:message, { channel: "cats" }, "meow")
