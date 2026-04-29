# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing::DetailedTrace do
  class SamplerSchema < GraphQL::Schema
    class Query < GraphQL::Schema::Object
      field :truthy, Boolean, fallback_value: true, resolve_static: true
      def self.truthy(ctx); true; end
    end

    query(Query)
    use GraphQL::Tracing::DetailedTrace, memory: true
    def self.detailed_trace?(query)
      if query.is_a?(GraphQL::Execution::Multiplex)
        query.queries.all? { |q| q.context[:profile] != false }
      else
        query.context[:profile] != false
      end
    end

    use GraphQL::Execution::Next
  end

  before do
    SamplerSchema.detailed_trace.delete_all_traces
  end

  def exec_query(...)
    if TESTING_EXEC_NEXT
      SamplerSchema.execute_next(...)
    else
      SamplerSchema.execute(...)
    end
  end

  def exec_multiplex(...)
    if TESTING_EXEC_NEXT
      SamplerSchema.multiplex_next(...)
    else
      SamplerSchema.multiplex(...)
    end
  end

  it "runs when the configured trace mode is set" do
    assert_equal 0, SamplerSchema.detailed_trace.traces.size
    res = exec_query("{ truthy }", context: { profile: false })
    assert_equal true, res["data"]["truthy"]
    assert_equal 0, SamplerSchema.detailed_trace.traces.size

    exec_query("{ truthy }")
    assert_equal 1, SamplerSchema.detailed_trace.traces.size
  end

  it "calls through to storage for access methods" do
    exec_query("{ truthy }")
    id = SamplerSchema.detailed_trace.traces.first.id
    assert_kind_of GraphQL::Tracing::DetailedTrace::StoredTrace, SamplerSchema.detailed_trace.find_trace(id)
    SamplerSchema.detailed_trace.delete_trace(id)
    assert_equal 0, SamplerSchema.detailed_trace.traces.size

    exec_query("{ truthy }")
    assert_equal 1, SamplerSchema.detailed_trace.traces.size
    SamplerSchema.detailed_trace.delete_all_traces
  end

  if testing_rails?
    it "defaults to ActiveRecord" do
      schema = Class.new(GraphQL::Schema) do
        use GraphQL::Tracing::DetailedTrace
      end

      assert_instance_of GraphQL::Tracing::DetailedTrace::ActiveRecordBackend, schema.detailed_trace.instance_variable_get(:@storage)
    end
  else
    it "raises when no storage is configured" do
      err = assert_raises ArgumentError do
        Class.new(GraphQL::Schema) do
          use GraphQL::Tracing::DetailedTrace
        end
      end
      assert_equal "To store traces, install ActiveRecord or provide `redis: ...`", err.message
    end
  end

  it "calls detailed_profile? on a Multiplex" do
    assert_equal 0, SamplerSchema.detailed_trace.traces.size

    exec_multiplex([
      { query: "{ truthy }", context: { profile: false } },
      { query: "{ truthy }", context: { profile: true } },
    ])
    assert_equal 0, SamplerSchema.detailed_trace.traces.size

    exec_multiplex([
      { query: "{ truthy }", context: { profile: true } },
      { query: "{ truthy }", context: { profile: true } },
    ])
    assert_equal 1, SamplerSchema.detailed_trace.traces.size
  end
end
