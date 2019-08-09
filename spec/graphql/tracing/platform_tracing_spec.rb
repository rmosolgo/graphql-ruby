# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing::PlatformTracing do
  class CustomPlatformTracer < GraphQL::Tracing::PlatformTracing
    TRACE = []

    self.platform_keys = {
      "lex" => "l",
      "parse" => "p",
      "validate" => "v",
      "analyze_query" => "aq",
      "analyze_multiplex" => "am",
      "execute_multiplex" => "em",
      "execute_query" => "eq",
      "execute_query_lazy" => "eql",
    }

    def platform_field_key(type, field)
      "#{type.graphql_name[0]}.#{field.graphql_name[0]}"
    end

    def platform_trace(platform_key, key, data)
      TRACE << platform_key
      yield
    end
  end

  describe "calling a platform tracer" do
    let(:schema) {
      Class.new(Dummy::Schema) { use(CustomPlatformTracer) }
    }

    before do
      CustomPlatformTracer::TRACE.clear
    end

    it "runs the introspection query (handles late-bound types)" do
      assert schema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)
    end

    it "calls the platform's own method with its own keys" do
      schema.execute(" { cheese(id: 1) { flavor } }")
      # This is different because schema/member/instrumentation
      # calls `irep_selection` which causes the query to be parsed.
      # But interpreter doesn't require parsing until later.
      expected_trace = if TESTING_INTERPRETER
        [
          "em",
          "am",
          "l",
          "p",
          "v",
          "aq",
          "eq",
          "Q.c", # notice that the flavor is skipped
          "eql",
        ]
      else
        ["em", "l", "p", "v", "am", "aq", "eq", "Q.c", "eql"]
      end

      assert_equal expected_trace, CustomPlatformTracer::TRACE
    end
  end

  describe "by default, scalar fields are not traced" do
    let(:schema) {
      Dummy::Schema.redefine {
        use(CustomPlatformTracer)
      }
    }

    before do
      CustomPlatformTracer::TRACE.clear
    end

    it "only traces traceTrue, not traceFalse or traceNil" do
      schema.execute(" { tracingScalar { traceNil traceFalse traceTrue } }")
      # This is different because schema/member/instrumentation
      # calls `irep_selection` which causes the query to be parsed.
      # But interpreter doesn't require parsing until later.
      expected_trace = if TESTING_INTERPRETER
        [
          "em",
          "am",
          "l",
          "p",
          "v",
          "aq",
          "eq",
          "Q.t",
          "T.t",
          "eql",
        ]
      else
        ["em", "l", "p", "v", "am", "aq", "eq", "Q.t", "T.t", "eql"]
      end
      assert_equal expected_trace, CustomPlatformTracer::TRACE
    end
  end

  describe "when scalar fields are traced by default, they are unless specified" do
    let(:schema) {
      Class.new(Dummy::Schema) do
        use(CustomPlatformTracer, trace_scalars: true)
      end
    }

    before do
      CustomPlatformTracer::TRACE.clear
    end

    it "traces traceTrue and traceNil but not traceFalse" do
      schema.execute(" { tracingScalar { traceNil traceFalse traceTrue } }")
      # This is different because schema/member/instrumentation
      # calls `irep_selection` which causes the query to be parsed.
      # But interpreter doesn't require parsing until later.
      expected_trace = if TESTING_INTERPRETER
        [
          "em",
          "am",
          "l",
          "p",
          "v",
          "aq",
          "eq",
          "Q.t",
          "T.t",
          "T.t",
          "eql",
        ]
      else
        ["em", "l", "p", "v", "am", "aq", "eq", "Q.t", "T.t", "T.t", "eql"]
      end
      assert_equal expected_trace, CustomPlatformTracer::TRACE
    end
  end
end
