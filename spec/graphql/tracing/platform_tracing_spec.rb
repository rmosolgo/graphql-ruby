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
      "#{type.name[0]}.#{field.name[0]}"
    end

    def platform_trace(platform_key, key, data)
      TRACE << platform_key
      yield
    end
  end

  describe "calling a platform tracer" do
    let(:schema) {
      Dummy::Schema.redefine {
        use(CustomPlatformTracer)
      }
    }

    before do
      CustomPlatformTracer::TRACE.clear
    end

    it "calls the platform's own method with its own keys" do
      schema.execute(" { cheese(id: 1) { flavor } }")
      expected_trace = [
        "em",
        "l",
        "p",
        "v",
        "am",
        "aq",
        "eq",
        "Q.c", # notice that the flavor is skipped
        "eql",
      ]
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
      expected_trace = [
        "em",
        "l",
        "p",
        "v",
        "am",
        "aq",
        "eq",
        "Q.t",
        "T.t",
        "eql",
      ]
      assert_equal expected_trace, CustomPlatformTracer::TRACE
    end
  end

  describe "when scalar fields are traced by default, they are unless specified" do
    let(:schema) {
      Dummy::Schema.redefine {
        use(CustomPlatformTracer, trace_scalars: true)
      }
    }

    before do
      CustomPlatformTracer::TRACE.clear
    end

    it "traces traceTrue and traceNil but not traceFalse" do
      schema.execute(" { tracingScalar { traceNil traceFalse traceTrue } }")
      expected_trace = [
        "em",
        "l",
        "p",
        "v",
        "am",
        "aq",
        "eq",
        "Q.t",
        "T.t",
        "T.t",
        "eql",
      ]
      assert_equal expected_trace, CustomPlatformTracer::TRACE
    end
  end
end
