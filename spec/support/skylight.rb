# frozen_string_literal: true
# A stub for the Skylight agent, so we can make assertions about how it is used
# Based on:
#  - https://www.rubydoc.info/gems/skylight-core/2.0.2
#  - https://www.rubydoc.info/gems/skylight/2.0.2
if defined?(Skylight)
  raise "Expected Skylight to be undefined, so that we could define a stub for it."
end

module Skylight
  ENDPOINT_NAMES = []
  # Reset state between tests
  def self.clear_all
    ENDPOINT_NAMES.clear
  end

  def self.instrumenter
    Instrumenter
  end

  def self.instrument(category:, title:)
    yield
  end

  module Instrumenter
    def self.current_trace
      CurrentTrace
    end
  end

  module CurrentTrace
    def self.endpoint=(endpoint)
      ENDPOINT_NAMES << endpoint
    end
  end
end
