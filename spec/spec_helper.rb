# frozen_string_literal: true
# Print full backtrace for failiures:
ENV["BACKTRACE"] = "1"

def rails_should_be_installed?
  ENV['WITHOUT_RAILS'] != 'yes'
end
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

if rails_should_be_installed?
  require "rake"
  require "rails/all"
  require "rails/generators"

  require "jdbc/sqlite3" if RUBY_ENGINE == 'jruby'
  require "sqlite3" if RUBY_ENGINE == 'ruby'
  require "pg" if RUBY_ENGINE == 'ruby'
  require "mongoid" if RUBY_ENGINE == 'ruby'
  require "sequel"
end

require "graphql"
require "graphql/rake_task"
require "benchmark"
require "pry"
require "minitest/autorun"
require "minitest/focus"
require "minitest/reporters"

MONGO_DETECTED = begin
  require "mongo"
  Mongo::Client.new('mongodb://127.0.0.1:27017/graphql_ruby_test',
      connect_timeout: 1,
      socket_timeout: 1,
      server_selection_timeout: 1,
      logger: Logger.new(nil)
    )
    .database
    .collections
rescue StandardError, LoadError => err # rubocop:disable Lint/UselessAssignment
  # puts err.message, err.backtrace
  false
end

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

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each do |f|
  # These require mongodb in order to run,
  # so only load them in the specific tests that require them.
  next if f.include?("star_trek")

  unless rails_should_be_installed?
    next if f.end_with?('star_wars/data.rb')
    next if f.end_with?('base_generator_test.rb')
  end
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
