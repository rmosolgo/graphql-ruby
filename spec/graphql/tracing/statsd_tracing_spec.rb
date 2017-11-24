# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing::StatsdTracing do
  class FakeStatsdClient
    attr_reader :counters, :timed_keys

    def self.client
      @client ||= new
    end

    def initialize
      reset
    end

    def count(key, delta)
      new_count = @counters.fetch(key, 0) + delta
      @counters[key] = new_count
    end

    def time(key, &block)
      @timed_keys << key
      block.call
    end

    def reset
      @counters = {}
      @timed_keys = []
    end
  end

  describe 'using statsd tracer' do
    before { FakeStatsdClient.client.reset }
    let(:schema) {
      Dummy::Schema.redefine {
        use(GraphQL::Tracing::StatsdTracing, statsd: FakeStatsdClient.client)
      }
    }

    it 'times operations' do
      schema.execute(" { cheese(id: 1) { flavor } }")
      expected_trace = [
        "execute.graphql",
        "analyze.graphql",
        "lex.graphql",
        "parse.graphql",
        "validate.graphql",
        "analyze.graphql",
        "execute.graphql",
        "Query.cheese", # notice that the flavor is skipped
        "execute.graphql",
      ]
      assert_equal expected_trace, FakeStatsdClient.client.timed_keys
    end

    it 'counts operation names' do
      schema.execute(" query kerk { cheese(id: 1) { flavor } }")
      schema.execute(" query kerk { cheese(id: 1) { flavor } }")
      schema.execute(" query { cheese(id: 1) { flavor } }")

      expected_counts = {
        "kerk" => 2,
        "<anonymous query>" => 1,
      }
      assert_equal expected_counts, FakeStatsdClient.client.counters
    end
  end
end
