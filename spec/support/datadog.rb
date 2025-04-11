# frozen_string_literal: true
# A stub for the Datadog agent, so we can make assertions about how it is used
if defined?(Datadog)
  raise "Expected Datadog to be undefined, so that we could define a stub for it."
end

module Datadog
  SPAN_RESOURCE_NAMES = []
  SPAN_TAGS = []
  TRACE_KEYS = []

  def self.tracer
    DummyTracer.new
  end

  def self.clear_all
    SPAN_RESOURCE_NAMES.clear
    SPAN_TAGS.clear
    TRACE_KEYS.clear
  end

  class DummyTracer
    def trace(platform_key, *args)
      TRACE_KEYS << platform_key
      yield DummySpan.new
    end
  end

  class DummySpan
    def resource=(resource_name)
      SPAN_RESOURCE_NAMES << resource_name
    end

    def set_tag(key, value)
      SPAN_TAGS << [key, value]
    end

    def finish
    end
  end

  module Tracing
    def self.trace(platform_key, *args)
      TRACE_KEYS << platform_key
      if block_given?
        yield DummySpan.new
      else
        DummySpan.new
      end
    end
  end
end
