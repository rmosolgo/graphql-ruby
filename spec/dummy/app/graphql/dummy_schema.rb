# frozen_string_literal: true

class DummySchema < GraphQL::Schema
  class Query < GraphQL::Schema::Object
    field :str, String, fallback_value: "hello"
  end

  query(Query)
  use GraphQL::Tracing::PerfettoSampler, memory: true
end
