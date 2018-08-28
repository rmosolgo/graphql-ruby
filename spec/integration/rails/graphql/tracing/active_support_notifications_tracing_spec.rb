# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing::ActiveSupportNotificationsTracing do
  let(:schema) {
    StarWars::Schema.redefine {
      tracer GraphQL::Tracing::ActiveSupportNotificationsTracing
    }
  }

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
      schema.execute(query_string, variables: {
        "id1" => first_id,
        "id2" => last_id,
      })
    end

    expected_traces = [
      "graphql.lex",
      "graphql.parse",
      "graphql.validate",
      "graphql.analyze_query",
      "graphql.analyze_multiplex",
      "graphql.execute_field",
      "graphql.execute_field",
      "graphql.execute_query",
      "graphql.lazy_loader",
      "graphql.execute_field_lazy",
      "graphql.execute_field",
      "graphql.execute_field_lazy",
      "graphql.execute_field",
      "graphql.execute_field_lazy",
      "graphql.execute_field_lazy",
      "graphql.execute_query_lazy",
      "graphql.execute_multiplex",
    ]
    assert_equal expected_traces, traces
  end
end
