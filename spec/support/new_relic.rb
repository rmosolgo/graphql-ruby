# frozen_string_literal: true
# A stub for the NewRelic agent, so we can make assertions about how it is used
if defined?(NewRelic)
  raise "Expected NewRelic to be undefined, so that we could define a stub for it."
end

module NewRelic
  TRANSACTION_NAMES = []
  # Reset state between tests
  def self.clear_all
    TRANSACTION_NAMES.clear
  end
  module Agent
    def self.set_transaction_name(name)
      TRANSACTION_NAMES << name
    end

    module MethodTracerHelpers
      def self.trace_execution_scoped(trace_name)
        yield
      end
    end
  end
end
