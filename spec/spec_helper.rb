require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
require "graphql"
require "benchmark"
require "minitest/autorun"
require "minitest/focus"
require "minitest/reporters"
require "pry"
require "sqlite3"
require "active_record"
require "sequel"
require "graphql/relay"
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

Minitest::Spec.make_my_diffs_pretty!

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# # Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

def query(string, variables={})
  GraphQL::Query.new(StarWarsSchema, string, variables: variables).result
end