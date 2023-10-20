# frozen_string_literal: true
# A stub for the Datadog agent, so we can make assertions about how it is used
if defined?(Datadog)
  raise "Expected Datadog to be undefined, so that we could define a stub for it."
end

module Datadog
  SPAN_RESOURCE_NAMES = []
  SPAN_TAGS = []

  def self.tracer
    DummyTracer.new
  end

  def self.clear_all
    SPAN_RESOURCE_NAMES.clear
    SPAN_TAGS.clear
  end


  module Contrib
    module Analytics
      def self.set_sample_rate(rate)
        rate
      end

      def self.enabled?(_bool)
        nil
      end
    end
  end

  class DummyTracer
    def trace(platform_key, *args)
      yield DummySpan.new
    end
  end

  class DummySpan
    def resource=(resource_name)
      SPAN_RESOURCE_NAMES << resource_name
    end

    def span_type=(*args)end
    def set_tag(key, value)
      SPAN_TAGS << [key, value]
    end
  end

  module Tracing
    def self.trace(platform_key, *args)
      yield DummySpan.new
    end

    module Metadata
      module Ext
        TAG_COMPONENT = 'component'
        TAG_OPERATION = 'operation'
      end
    end
  end
end
