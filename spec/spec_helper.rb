# frozen_string_literal: true

require 'rubygems'
require 'bundler'
Bundler.require

# Print full backtrace for failiures:
ENV["BACKTRACE"] = "1"

require "graphql"
require "rake"
require "graphql/rake_task"
require "benchmark"
require "pry"
require "minitest/autorun"
require "minitest/focus"
require "minitest/reporters"

Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new(color: true)

Minitest::Spec.make_my_diffs_pretty!

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# Can be used as a GraphQL::Schema::Warden for some purposes, but allows nothing
module NothingWarden
  def self.enum_values(enum_type)
    []
  end
end

# Use this when a schema requires a `resolve_type` hook
# but you know it won't be called
NO_OP_RESOLVE_TYPE = ->(type, obj, ctx) {
  raise "this should never be called"
}

def testing_rails?
  defined?(::Rails)
end

def testing_mongoid?
  defined?(::Mongoid)
end

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each do |f|
  require f
end

if testing_rails?
  require "integration/rails/spec_helper"
end

# Load dependencies
['Mongoid', 'Rails'].each do |integration|
  integration_loaded = begin
    Object.const_get(integration)
  rescue NameError
    nil
  end
  if ENV["TEST"].nil? && integration_loaded
    Dir["spec/integration/#{integration.downcase}/**/*.rb"].each do |f|
      require f.sub("spec/", "")
    end
  end
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
      data[:path] ||= data.key?(:context) ? data[:context].path : nil
      result = yield
      data[:result] = result
      traces << data
      result
    end
  end
end
