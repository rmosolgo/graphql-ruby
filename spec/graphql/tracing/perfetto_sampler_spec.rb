# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing::PerfettoSampler do
  class SamplerSchema < GraphQL::Schema
    class Query < GraphQL::Schema::Object
      field :truthy, Boolean, fallback_value: true
    end

    query(Query)
    use GraphQL::Tracing::PerfettoSampler, memory: true
  end

  before do
    SamplerSchema.perfetto_sampler.delete_all_traces
  end

  it "runs when the configured trace mode is set" do
    skip("Skipping")
    assert_equal 0, SamplerSchema.perfetto_sampler.traces.size
    res = SamplerSchema.execute("{ truthy }")
    assert_equal true, res["data"]["truthy"]
    assert_equal 0, SamplerSchema.perfetto_sampler.traces.size

    SamplerSchema.execute("{ truthy }", context: { trace_mode: :perfetto_sample })
    assert_equal 1, SamplerSchema.perfetto_sampler.traces.size
  end

  it "calls through to storage for access methods" do
    # skip("Skipping")
    SamplerSchema.execute("{ truthy }", context: { trace_mode: :perfetto_sample })
    id = SamplerSchema.perfetto_sampler.traces.first.id
    assert_kind_of GraphQL::Tracing::PerfettoSampler::StoredTrace, SamplerSchema.perfetto_sampler.find_trace(id)
    SamplerSchema.perfetto_sampler.delete_trace(id)
    assert_equal 0, SamplerSchema.perfetto_sampler.traces.size

    SamplerSchema.execute("{ truthy }", context: { trace_mode: :perfetto_sample })
    assert_equal 1, SamplerSchema.perfetto_sampler.traces.size
    SamplerSchema.perfetto_sampler.delete_all_traces
  end

  it "raises when no storage is configured" do
    err = assert_raises ArgumentError do
      Class.new(GraphQL::Schema) do
        use GraphQL::Tracing::PerfettoSampler, active_record: false
      end
    end
    assert_equal "A storage option must be chosen", err.message
  end
end
