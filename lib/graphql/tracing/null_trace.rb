# frozen_string_literal: true
# typed: true

require "graphql/tracing/trace"

module GraphQL
  module Tracing
    NullTrace = Trace.new.freeze
  end
end
