# frozen_string_literal: true
require "bundler/setup"
Bundler::GemHelper.install_tasks

require "rake/testtask"
require_relative "guides/_tasks/site"
require_relative "lib/graphql/rake_task/validate"
require 'rake/extensiontask'

Rake::TestTask.new do |t|
  t.libs << "spec" << "lib" << "graphql-c_parser/lib"

  exclude_integrations = []
  ['Mongoid', 'Rails'].each do |integration|
    begin
      Object.const_get(integration)
    rescue NameError
      exclude_integrations << integration.downcase
    end
  end

  t.test_files = Dir['spec/**/*_spec.rb'].reject do |f|
    next unless f.start_with?("spec/integration/")
    excluded = exclude_integrations.any? do |integration|
      f.start_with?("spec/integration/#{integration}/")
    end
    puts "+ #{f}" unless excluded
    excluded
  end

  t.warning = false
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new

default_tasks = [:test, :rubocop]
if ENV["SYSTEM_TESTS"]
  task(default: ["test:system"] + default_tasks)
else
  task(default: default_tasks)
end

def assert_dependency_version(dep_name, required_version, check_script)
  version = `#{check_script}`
  if !version.include?(required_version)
    raise <<-ERR
build_parser requires #{dep_name} version "#{required_version}", but found:

  $ #{check_script}
  > #{version}

To fix this issue:

- Update #{dep_name} to the required version
- Update the assertion in `Rakefile` to match the current version
ERR
  end
end

desc "Use Racc to regenerate parser.rb from configuration files"
task :build_parser do
  assert_dependency_version("Racc", "1.6.2", %|ruby -e "require 'racc'; puts Racc::VERSION"|)

  `rm -f lib/graphql/language/parser.rb `
  `racc lib/graphql/language/parser.y -o lib/graphql/language/parser.rb`
end

namespace :bench do
  def prepare_benchmark
    $LOAD_PATH << "./lib" << "./spec/support"
    require_relative("./benchmark/run.rb")
  end

  desc "Benchmark parsing"
  task :parse do
    prepare_benchmark
    GraphQLBenchmark.run("parse")
  end

  desc "Benchmark lexical analysis"
  task :scan do
    prepare_benchmark
    GraphQLBenchmark.run("scan")
  end

  desc "Benchmark the introspection query"
  task :query do
    prepare_benchmark
    GraphQLBenchmark.run("query")
  end

  desc "Benchmark validation of several queries"
  task :validate do
    prepare_benchmark
    GraphQLBenchmark.run("validate")
  end

  desc "Profile a validation"
  task :validate_memory do
    prepare_benchmark
    GraphQLBenchmark.validate_memory
  end

  desc "Generate a profile of the introspection query"
  task :profile do
    prepare_benchmark
    GraphQLBenchmark.profile
  end

  desc "Run benchmarks on a very large result"
  task :profile_large_result do
    prepare_benchmark
    GraphQLBenchmark.profile_large_result
  end

  desc "Compare GraphQL-Batch and GraphQL-Dataloader"
  task :profile_batch_loaders do
    prepare_benchmark
    GraphQLBenchmark.profile_batch_loaders
  end

  desc "Check the memory footprint of a large schema"
  task :profile_schema_memory_footprint do
    prepare_benchmark
    GraphQLBenchmark.profile_schema_memory_footprint
  end

  desc "Check the depth of the stacktrace during execution"
  task :profile_stack_depth do
    prepare_benchmark
    GraphQLBenchmark.profile_stack_depth
  end

  desc "Run a very big introspection query"
  task :profile_large_introspection do
    prepare_benchmark
    GraphQLBenchmark.profile_large_introspection
  end

  desc "Run analysis on a big query"
  task :profile_large_analysis do
    prepare_benchmark
    GraphQLBenchmark.profile_large_analysis
  end

  desc "Run analysis on parsing"
  task :profile_parse do
    prepare_benchmark
    GraphQLBenchmark.profile_parse
  end
end

namespace :test do
  desc "Run system tests for ActionCable subscriptions"
  task :system do
    success = Dir.chdir("spec/dummy") do
      system("bundle install")
      system("bundle exec bin/rails test:system")
    end
    success || abort
  end

  task js: "js:test"
end

namespace :js do
  client_dir = "./javascript_client"

  desc "Run the tests for javascript_client"
  task :test do
    success = Dir.chdir(client_dir) do
      system("yarn run test")
    end
    success || abort
  end

  desc "Install JS dependencies"
  task :install do
    Dir.chdir(client_dir) do
      system("yarn install")
    end
  end

  desc "Compile TypeScript to JavaScript"
  task :build do
    Dir.chdir(client_dir) do
      system("yarn tsc")
    end
  end
  task all: [:install, :build, :test]
end

task :build_c_lexer do
  assert_dependency_version("Ragel", "7.0.4", "ragel -v")
  `ragel -F1 graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl`
end

Rake::ExtensionTask.new("graphql_c_parser_ext") do |ext|
  ext.ext_dir = 'graphql-c_parser/ext/graphql_c_parser_ext' # search for 'hello_world' inside it.
end

desc "Build the C Extension"
task build_ext: [:build_c_lexer, "compile:graphql_c_parser_ext"]
