require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
require "sqlite3"
require "active_record"
require "sequel"
require "graphql"
require "benchmark"
require "minitest/autorun"
require "minitest/focus"
require "minitest/reporters"
require "pry"
require 'pry-stack_explorer'
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

Minitest::Spec.make_my_diffs_pretty!

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

def star_wars_query(string, variables={})
  GraphQL::Query.new(StarWarsSchema, string, variables: variables).result
end

module StaticAnalysisHelpers
  def get_errors(query_string)
    query_ast = GraphQL.parse(query_string)
    visitor = GraphQL::Language::Visitor.new(query_ast)
    analysis = GraphQL::StaticAnalysis.prepare(visitor)
    visitor.visit
    analysis.errors
  end

  def assert_errors(query_string, *expected_error_messages)
    errors = get_errors(query_string)
    messages = errors.map(&:message)
    expected_error_messages.each do |expected_message|
      assert_includes(messages, expected_message)
    end
    assert_equal(expected_error_messages.length, messages.length, "Found the expected number of errors")
  end
end
