#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Fast core test suite for graphql-ruby.
# Excludes: async IO, ActiveRecord, nonblocking dataloader, known-failing tests,
# integration tests, and SimpleCov for speed.
#
# Usage: bundle exec ruby -Ispec -Ilib -Igraphql-c_parser/lib test_fast.rb

# Skip SimpleCov for speed - stub it out before anything loads it
module SimpleCov
  module Formatter
    class LcovFormatter
      def self.config; self; end
      def self.report_with_single_file=(v); end
    end
    class HTMLFormatter; end
  end
  def self.formatters=(v); end
  def self.start(*args, &block); end
end

require 'rubygems'
require 'bundler'
Bundler.require

ENV["BACKTRACE"] = "1"

require "graphql"
if ENV["GRAPHQL_CPARSER"]
  USING_C_PARSER = true
  require "graphql-c_parser"
else
  USING_C_PARSER = false
end

if ENV["GRAPHQL_FUTURE"]
  GraphQL.reject_numbers_followed_by_names = true
  GraphQL::Schema.use(GraphQL::Schema::Visibility, migration_errors: true)
  ADD_WARDEN = false
  TESTING_EXEC_NEXT = false
else
  ADD_WARDEN = true
  TESTING_EXEC_NEXT = false
end

RUN_RACTOR_TESTS = false

require "rake"
require "graphql/rake_task"
require "pry"
require "minitest/autorun"
require "minitest/focus"
require "minitest/reporters"
require "graphql/batch"

running_in_rubymine = ENV["RM_INFO"]
unless running_in_rubymine
  Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new(color: true)
end

Minitest::Spec.make_my_diffs_pretty!

# Warden shape checker from spec_helper
module CheckWardenShape
  DEFAULT_SHAPE = GraphQL::Schema::Warden.new(context: {}, schema: GraphQL::Schema).instance_variables

  class CheckShape
    def initialize(warden)
      @warden = warden
    end

    def call(_obj_id)
      ivars = @warden.instance_variables
      if ivars != DEFAULT_SHAPE
        raise <<-ERR
Object Shape Failed (#{@warden.class}):
  - Expected: #{DEFAULT_SHAPE.inspect}
  - Actual: #{ivars.inspect}
ERR
      end
    end
  end

  def prepare_ast
    super
    setup_finalizer
  end

  private

  def setup_finalizer
    if !@finalizer_defined
      @finalizer_defined = true
      if warden.is_a?(GraphQL::Schema::Warden)
        ObjectSpace.define_finalizer(self, CheckShape.new(warden))
      end
    end
  end
end

GraphQL::Query.prepend(CheckWardenShape)
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

module NothingWarden
  def self.enum_values(enum_type)
    []
  end
end

NO_OP_RESOLVE_TYPE = ->(type, obj, ctx) {
  raise "this should never be called"
}

def testing_rails?
  defined?(::Rails)
end

def testing_mongoid?
  defined?(::Mongoid)
end

def testing_redis?
  defined?(::Redis)
end

# Load support files
Dir["#{File.dirname(__FILE__)}/spec/support/**/*.rb"].each do |f|
  require f
end

def star_trek_query(string, variables={}, context: {})
  StarTrek::Schema.execute(string, variables: variables, context: context)
end

def star_wars_query(string, variables={}, context: {})
  StarWars::Schema.execute(string, variables: variables, context: context)
end

def with_bidirectional_pagination
  prev_value = GraphQL::Relay::ConnectionType.bidirectional_pagination
  GraphQL::Relay::ConnectionType.bidirectional_pagination = true
  yield
ensure
  GraphQL::Relay::ConnectionType.bidirectional_pagination = prev_value
end

module TestTracing
  class << self
    def clear
      traces.clear
    end

    def with_trace
      clear
      yield
      traces
    end

    def traces
      @traces ||= []
    end

    def trace(key, data)
      data[:key] = key
      result = yield
      data[:result] = result
      traces << data
      result
    end
  end
end

if !USING_C_PARSER && defined?(GraphQL::CParser::Parser)
  raise "Load error: didn't opt in to C parser but GraphQL::CParser::Parser was defined"
end

def assert_warns(warning, printing = "")
  return_val = nil
  stdout, stderr = capture_io { return_val = yield }
  assert_equal warning, stderr, "It produced the expected stderr"
  assert_equal stdout, printing, "It produced the expected stdout"
  return_val
end

module Minitest
  class Test
    def self.it_dataloads(message, &block)
      it(message) do
        GraphQL::Dataloader.with_dataloading do |d|
          self.instance_exec(d, &block)
        end
      end
    end
  end

  module Assertions
    def assert_graphql_equal(data1, data2, message = "GraphQL Result was equal")
      case data1
      when Hash
        assert_equal(data1, data2, message)
        assert_equal(data1.keys, data2.keys, "Order of keys matched (#{message})")
      when Array
        data1.each_with_index do |item1, idx|
          assert_graphql_equal(item1, data2[idx], message + "[Item #{idx + 1}] ")
        end
      else
        raise ArgumentError, "assert_graphql_equal doesn't support #{data1.class} yet"
      end
    end
  end
end

# --- Exclusion list ---
EXCLUDE_PATTERNS = [
  'dataloader',
  'active_record',
  'autoload_spec',
  'prometheus_tracing_spec',
  'ractor_shareable_spec',
  'mongoid',
  'sequel',
  'redis_backend_spec',
  'active_record_backend_spec',
]

spec_files = Dir.glob("spec/graphql/**/*_spec.rb").reject do |f|
  EXCLUDE_PATTERNS.any? { |pat| f.include?(pat) }
end

spec_files.sort.each { |f| require_relative f }
