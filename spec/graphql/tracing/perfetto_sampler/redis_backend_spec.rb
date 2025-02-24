# frozen_string_literal: true
require "spec_helper"
require_relative "./backend_assertions"

if testing_redis?
  describe GraphQL::Tracing::PerfettoSampler::RedisBackend do
    include GraphQLTracingPerfettoSamplerBackendAssertions
    def new_backend(**kwargs)
      GraphQL::Tracing::PerfettoSampler::RedisBackend.new(redis: Redis.new, **kwargs)
    end
  end
end
