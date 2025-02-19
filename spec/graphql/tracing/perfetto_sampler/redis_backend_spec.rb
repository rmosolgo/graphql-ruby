# frozen_string_literal: true
require "spec_helper"
require_relative "./backend_assertions"

if defined?(::Redis)
  describe GraphQL::Tracing::PerfettoSampler::RedisBackend do
    include GraphQLTracingPerfettoSamplerBackendAssertions

    before do
      @backend = GraphQL::Tracing::PerfettoSampler::RedisBackend.new(redis: Redis.new)
    end
  end
end
