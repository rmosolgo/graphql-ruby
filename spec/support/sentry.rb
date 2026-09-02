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

  class DataCollection
    class GraphQL
      attr_accessor :document, :variables

      def initialize
        @document = true
        @variables = true
      end
    end

    attr_reader :graphql

    def initialize
      @graphql = GraphQL.new
    end
  end

  class Configuration
    attr_reader :data_collection

    def initialize
      @data_collection = DataCollection.new
    end
  end

  class << self
    attr_accessor :use_nil_span
  end

  def self.initialized?
    true
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.utc_now
    Time.now.utc
  end

  def self.get_current_scope
    self
  end

  def self.get_span
    use_nil_span ? nil : DummySpan
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
    configuration.data_collection.graphql.document = true
    configuration.data_collection.graphql.variables = true
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
