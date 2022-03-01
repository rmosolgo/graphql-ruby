# frozen_string_literal: true
require "bundler/setup"
Bundler.require
Bundler::GemHelper.install_tasks

require "rake/testtask"
require_relative "guides/_tasks/site"
require_relative "lib/graphql/rake_task/validate"


Rake::TestTask.new do |t|
  t.libs << "spec" << "lib"

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

desc "Use Racc & Ragel to regenerate parser.rb & lexer.rb from configuration files"
task :build_parser do
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

  assert_dependency_version("Ragel", "7.0.0.9", "ragel -v")
  assert_dependency_version("Racc", "1.6.0", %|ruby -e "require 'racc'; puts Racc::VERSION"|)

  `rm -f lib/graphql/language/parser.rb lib/graphql/language/lexer.rb `
  `racc lib/graphql/language/parser.y -o lib/graphql/language/parser.rb`
  `ragel -R -F1 lib/graphql/language/lexer.rl`
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
