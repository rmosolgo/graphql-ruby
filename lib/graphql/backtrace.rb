# frozen_string_literal: true
require "graphql/backtrace/inspect_result"
require "graphql/backtrace/table"
require "graphql/backtrace/traced_error"
require "graphql/backtrace/tracer"
require "graphql/backtrace/trace"
module GraphQL
  # Wrap unhandled errors with {TracedError}.
  #
  # {TracedError} provides a GraphQL backtrace with arguments and return values.
  # The underlying error is available as {TracedError#cause}.
  #
  # @example toggling backtrace annotation
  #   class MySchema < GraphQL::Schema
  #     if Rails.env.development? || Rails.env.test?
  #       use GraphQL::Backtrace
  #     end
  #   end
  #
  class Backtrace
    include Enumerable
    extend Forwardable

    def_delegators :to_a, :each, :[]

    def self.use(schema_defn)
      schema_defn.trace_with(self::Trace)
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

    # Used for internal bookkeeping
    # @api private
    class Frame
      attr_reader :path, :query, :ast_node, :object, :field, :arguments, :parent_frame
      def initialize(path:, query:, ast_node:, object:, field:, arguments:, parent_frame:)
        @path = path
        @query = query
        @ast_node = ast_node
        @field = field
        @object = object
        @arguments = arguments
        @parent_frame = parent_frame
      end
    end
  end
end
