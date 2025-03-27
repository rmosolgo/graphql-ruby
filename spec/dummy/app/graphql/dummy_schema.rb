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
  use GraphQL::Tracing::DetailedTrace, memory: true

  if defined?(GraphQL::Pro)
    use GraphQL::Pro::OperationStore, redis: Redis.new(db: Rails.env.test? ? 1 : 0)
  end

  def self.detailed_trace?(query)
    query.context[:profile]
  end
end
