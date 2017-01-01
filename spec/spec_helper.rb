# frozen_string_literal: true
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
require "sqlite3"
require "active_record"
require "action_controller"
require "sequel"
require "graphql"
require "benchmark"
require "minitest/autorun"
require "minitest/focus"
require "minitest/reporters"
Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new(color: true)

Minitest::Spec.make_my_diffs_pretty!

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new


# This is for convenient access to metadata in test definitions
assign_metadata_key = -> (target, key, value) { target.metadata[key] = value }
GraphQL::BaseType.accepts_definitions(metadata: assign_metadata_key)
GraphQL::Field.accepts_definitions(metadata: assign_metadata_key)
GraphQL::Argument.accepts_definitions(metadata: assign_metadata_key)
GraphQL::EnumType::EnumValue.accepts_definitions(metadata: assign_metadata_key)

# Can be used as a GraphQL::Schema::Warden for some purposes, but allows anything
module PermissiveWarden
  def self.arguments(input_obj)
    input_obj.arguments.values
  end

  def self.enum_values(enum_type)
    enum_type.values.values
  end
end

# Can be used as a GraphQL::Schema::Warden for some purposes, but allows nothing
module NothingWarden
  def self.enum_values(enum_type)
    []
  end
end

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

def star_wars_query(string, variables={})
  GraphQL::Query.new(StarWarsSchema, string, variables: variables).result
end
