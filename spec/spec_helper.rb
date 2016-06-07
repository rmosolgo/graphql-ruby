require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
require "sqlite3"
require "active_record"
require "sequel"
require "graphql/relay"
require "minitest/autorun"
require "minitest/focus"
require "minitest/reporters"
require 'pry'
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
# Filter out Minitest backtrace while allowing backtrace from other libraries to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }


def query(string, variables={})
  GraphQL::Query.new(StarWarsSchema, string, variables: variables, debug: true).result
end
