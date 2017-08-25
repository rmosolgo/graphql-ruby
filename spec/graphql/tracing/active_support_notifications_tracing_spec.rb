# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing::ActiveSupportNotificationsTracing do
  before do
    @prev_tracer = GraphQL::Tracing.tracer
    GraphQL::Tracing.install(GraphQL::Tracing::ActiveSupportNotificationsTracing)
  end

  after do
    GraphQL::Tracing.install(@prev_tracer)
  end

  it "pushes through AS::N" do
    traces = []

    callback = ->(name, started, finished, id, data) {
      traces << name
    }

    query_string = <<-GRAPHQL
    query Bases($id1: ID!, $id2: ID!){
      b1: batchedBase(id: $id1) { name }
      b2: batchedBase(id: $id2) { name }
    }
    GRAPHQL
    first_id = StarWars::Base.first.id
    last_id = StarWars::Base.last.id

    ActiveSupport::Notifications.subscribed(callback, /^graphql/) do
      star_wars_query(query_string, {
        "id1" => first_id,
        "id2" => last_id,
      })
    end

    expected_traces = [
      "graphql.lex",
      "graphql.parse",
      "graphql.validate",
      "graphql.analyze.query",
      "graphql.analyze.multiplex",
      "graphql.execute.field",
      "graphql.execute.field",
      "graphql.execute.eager",
      "graphql.lazy_loader",
      "graphql.execute.field",
      "graphql.execute.field.lazy",
      "graphql.execute.field",
      "graphql.execute.field.lazy",
      "graphql.execute.field.lazy",
      "graphql.execute.field.lazy",
      "graphql.execute.lazy",
    ]
    assert_equal expected_traces, traces
  end
end
