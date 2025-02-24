# frozen_string_literal: true
require "spec_helper"
require_relative "./backend_assertions"

describe GraphQL::Tracing::PerfettoSampler::MemoryBackend do
  include GraphQLTracingPerfettoSamplerBackendAssertions
  def new_backend(**kwargs)
    GraphQL::Tracing::PerfettoSampler::MemoryBackend.new(**kwargs)
  end
end
