# frozen_string_literal: true
# Use a rails gemfile for this because it has the widest coverage
def testing_coverage?
  ENV["COVERAGE"]
end

def ci_running?
  ENV["GITHUB_ACTIONS"]
end

# Enable code coverage when opted in and no specific file was selected
if testing_coverage? && !ENV["TEST"]
  puts "Starting Code Coverage"
  require 'simplecov'
  SimpleCov.at_exit do
    text_result = +""
    SimpleCov.result.groups.each do |name, files|
      text_result << "Group: #{name}\n"
      text_result << "=" * 40
      text_result << "\n"
      files.each do |file|
        text_result << "#{file.filename} (coverage: #{file.covered_percent.round(2)}% / branch: #{file.branches_coverage_percent.round(2)}%)\n"
      end
      text_result << "\n"
    end
    # Write this file to track coverage in source control
    cov_file = "spec/artifacts/coverage.txt"
    # Raise in CI if this file isn't up-to-date
    if ci_running?
      FileUtils.mkdir_p("spec/ci")
      File.write("spec/ci/coverage.txt", text_result)
      ci_artifact_paths = Dir.glob("spec/ci/*.txt")
      any_artifact_changes = ci_artifact_paths.any? do |ci_artifact_path|
        committed_artifact_path = ci_artifact_path.sub("/ci/", "/artifacts/")
        File.read(ci_artifact_path) != File.read(committed_artifact_path)
      end
      if any_artifact_changes
        if `git config --global user.name` == ""
          `git config --global user.name "GraphQL-Ruby CI"`
          `git config --global user.email "<>"`
        end
        current_branch = ENV["GITHUB_HEAD_REF"].sub("refs/heads/", "")
        `git checkout #{current_branch}`
        current_sha = `git rev-parse HEAD`.chomp
        new_branch = "update-artifacts-on-#{current_branch}-#{current_sha[0, 10]}"
        `git checkout -b #{new_branch}`
        ci_artifact_paths.each do |ci_artifact_path|
          FileUtils.cp(ci_artifact_path, ci_artifact_path.sub("/ci/", "/artifacts/"))
        end
        `git add spec`
        `git commit -m "Update artifacts (automatic)"`
        `git push origin #{new_branch}`
      end
    else
      FileUtils.mkdir_p("spec/artifacts")
      File.write(cov_file, text_result)
    end
    SimpleCov.result.format!
  end

  SimpleCov.start do
    enable_coverage :branch
    primary_coverage :branch
    add_filter %r{^/spec/}
    add_group "Schema Definition", [
      "lib/graphql/schema",
      "lib/graphql/types",
      "lib/graphql/type_kinds.rb",
      "lib/graphql/rake_task",
      "lib/graphql/rubocop",
      "lib/graphql/invalid_name_error.rb",
      "lib/graphql/name_validator.rb",
    ]
    add_group "Language", [
      "lib/graphql/language",
      "lib/graphql/parse_error.rb",
      "lib/graphql/railtie.rb",
    ]
    add_group "Dataloader", ["lib/graphql/dataloader"]
    add_group "Pagination", ["lib/graphql/pagination"]
    add_group "Introspection", ["lib/graphql/introspection"]
    add_group "Execution", [
      "lib/graphql/static_validation",
      "lib/graphql/analysis",
      "lib/graphql/analysis_error.rb",
      "lib/graphql/backtrace",
      "lib/graphql/errors",
      "lib/graphql/execution",
      "lib/graphql/query",
      "lib/graphql/relay",
      "lib/graphql/tracing",
      "lib/graphql/runtime_type_error.rb",
      "lib/graphql/load_application_object_failed_error.rb",
      "lib/graphql/filter.rb",
      "lib/graphql/dig.rb",
      "lib/graphql/unauthorized_error.rb",
      "lib/graphql/unauthorized_field_error.rb",
      "lib/graphql/invalid_null_error.rb",
      "lib/graphql/coercion_error.rb",
      "lib/graphql/integer_encoding_error.rb",
      "lib/graphql/integer_decoding_error.rb",
      "lib/graphql/string_encoding_error.rb",
      "lib/graphql/runtime_type_error.rb",
      "lib/graphql/unresolved_type_error.rb",
    ]
    add_group "Subscriptions", ["lib/graphql/subscriptions"]
    add_group "Generators", "lib/generators"

    formatter SimpleCov::Formatter::HTMLFormatter
  end
end

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
