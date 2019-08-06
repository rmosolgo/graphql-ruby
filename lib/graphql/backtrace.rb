# frozen_string_literal: true
require "graphql/backtrace/inspect_result"
require "graphql/backtrace/table"
require "graphql/backtrace/traced_error"
require "graphql/backtrace/tracer"
module GraphQL
  # Wrap unhandled errors with {TracedError}.
  #
  # {TracedError} provides a GraphQL backtrace with arguments and return values.
  # The underlying error is available as {TracedError#cause}.
  #
  # WARNING: {.enable} is not threadsafe because {GraphQL::Tracing.install} is not threadsafe.
  #
  # @example toggling backtrace annotation
  #   # to enable:
  #   GraphQL::Backtrace.enable
  #   # later, to disable:
  #   GraphQL::Backtrace.disable
  #
  class Backtrace
    include Enumerable
    extend Forwardable

    def_delegators :to_a, :each, :[]

    def self.enable
      warn("GraphQL::Backtrace.enable is deprecated, add `use GraphQL::Backtrace` to your schema definition instead.")
      GraphQL::Tracing.install(Backtrace::Tracer)
      nil
    end

    def self.disable
      GraphQL::Tracing.uninstall(Backtrace::Tracer)
      nil
    end

    def self.use(schema_defn)
      schema_defn.tracer(self::Tracer)
    end

    def initialize(context, value: nil)
      @table = Table.new(context, value: value)
    end

    def inspect
      @table.to_table
    end

    alias :to_s :inspect

    def to_a
      @table.to_backtrace
    end
  end
end
