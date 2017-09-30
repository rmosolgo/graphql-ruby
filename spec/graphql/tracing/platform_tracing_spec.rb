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
        "am",
        "l",
        "p",
        "v",
        "aq",
        "eq",
        "Q.c", # notice that the flavor is skipped
        "eql",
      ]
      assert_equal expected_trace, CustomPlatformTracer::TRACE
    end
  end
end
