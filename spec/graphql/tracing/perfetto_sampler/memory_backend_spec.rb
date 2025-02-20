# frozen_string_literal: true
require "spec_helper"
require_relative "./backend_assertions"

describe GraphQL::Tracing::PerfettoSampler::MemoryBackend do
  include GraphQLTracingPerfettoSamplerBackendAssertions

  before do
    @backend = GraphQL::Tracing::PerfettoSampler::MemoryBackend.new
  end
end
