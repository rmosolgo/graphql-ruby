# frozen_string_literal: true

require 'rubygems'
require 'bundler'
Bundler.require

# Print full backtrace for failiures:
ENV["BACKTRACE"] = "1"
# Set this env var to use Interpreter for fixture schemas.
# Eventually, interpreter will be the default.
TESTING_INTERPRETER = ENV["TESTING_INTERPRETER"]

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

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

# This is for convenient access to metadata in test definitions
assign_metadata_key = ->(target, key, value) { target.metadata[key] = value }
assign_metadata_flag = ->(target, flag) { target.metadata[flag] = true }
GraphQL::Schema.accepts_definitions(set_metadata: assign_metadata_key)
GraphQL::BaseType.accepts_definitions(metadata: assign_metadata_key)
GraphQL::BaseType.accepts_definitions(metadata2: assign_metadata_key)
GraphQL::Field.accepts_definitions(metadata: assign_metadata_key)
GraphQL::Argument.accepts_definitions(metadata: assign_metadata_key)
GraphQL::Argument.accepts_definitions(metadata_flag: assign_metadata_flag)
GraphQL::EnumType::EnumValue.accepts_definitions(metadata: assign_metadata_key)

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

# Load dependencies
['Mongoid', 'Rails'].each do |integration|
  begin
    Object.const_get(integration)
    Dir["#{File.dirname(__FILE__)}/integration/#{integration.downcase}/**/*.rb"].each do |f|
      if f.end_with?("spec_helper.rb") || ENV["TEST"].nil?
        require f
      end
    end
  rescue NameError
    # ignore
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

class NoOpTracer
  def trace(_key, data)
    if (query = data[:query])
      query.context[:no_op_tracer_ran] = true
    end
    yield
  end
end

class NoOpInstrumentation
  def before_query(query)
    query.context[:no_op_instrumentation_ran_before_query] = true
  end

  def after_query(query)
    query.context[:no_op_instrumentation_ran_after_query] = true
  end
end

class NoOpAnalyzer < GraphQL::Analysis::AST::Analyzer
  def initialize(query_or_multiplex)
    query_or_multiplex.context[:no_op_analyzer_ran_initialize] = true
    super
  end

  def on_leave_field(_node, _parent, visitor)
    visitor.query.context[:no_op_analyzer_ran_on_leave_field] = true
  end

  def result
    query.context[:no_op_analyzer_ran_result] = true
  end
end

module PluginWithInstrumentationTracingAndAnalyzer
  def self.use(schema_defn)
    schema_defn.instrument :query, NoOpInstrumentation.new
    schema_defn.tracer NoOpTracer.new
    schema_defn.query_analyzer NoOpAnalyzer
  end
end
