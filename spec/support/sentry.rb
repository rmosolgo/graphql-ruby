# frozen_string_literal: true

# A stub for the Sentry agent, so we can make assertions about how it is used
if defined?(Sentry)
  raise "Expected Sentry to be undefined, so that we could define a stub for it."
end

module Sentry
  SPAN_OPS = []
  SPAN_DATA = []
  SPAN_DESCRIPTIONS = []
  TRANSACTION_NAMES = []

  def self.initialized?
    true
  end

  def self.utc_now
    Time.now.utc
  end

  def self.get_current_scope
    self
  end

  def self.get_span
    DummySpan
  end

  def self.with_child_span(**args, &block)
    SPAN_OPS << args[:op]
    yield DummySpan
  end

  def self.configure_scope(&block)
    yield DummyScope
  end

  def self.clear_all
    SPAN_DATA.clear
    SPAN_DESCRIPTIONS.clear
    SPAN_OPS.clear
    TRANSACTION_NAMES.clear
  end

  module DummySpan
    module_function
    def set_data(key, value)
      Sentry::SPAN_DATA << [key, value]
    end

    def set_description(description)
      Sentry::SPAN_DESCRIPTIONS << description
    end

    def start_child(op:)
      SPAN_OPS << op
    end

    def finish
      # no-op
    end
  end

  module DummyScope
    module_function
    def set_transaction_name(name)
      TRANSACTION_NAMES << name
    end
  end
end
