# frozen_string_literal: true
# A stub for the Scout agent, so we can make assertions about how it is used
if defined?(ScoutApm)
  raise "Expected ScoutApm to be undefined, so that we could define a stub for it."
end

class ScoutApm
  TRANSACTION_NAMES = []
  EVENTS = []

  def self.clear_all
    TRANSACTION_NAMES.clear
    EVENTS.clear
  end

  module Tracer
    def self.instrument(type, name, options = {})
      EVENTS << name
      yield
    end
  end

  class Layer
    def initialize(type, name)
      EVENTS << name
    end

    def subscopable!
      nil
    end
  end

  module RequestManager
    def self.lookup
      self
    end

    def self.start_layer(_layer)
      nil
    end

    def self.stop_layer
      nil
    end
  end

  module Transaction
    def self.rename(name)
      ScoutApm::TRANSACTION_NAMES << name
    end
  end
end
