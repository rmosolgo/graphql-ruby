# frozen_string_literal: true
require "bundler/setup"
Bundler::GemHelper.install_tasks

require "rake/testtask"
require_relative "guides/_tasks/site"
require_relative "lib/graphql/rake_task/validate"

Rake::TestTask.new do |t|
  t.libs << "spec" << "lib"

  if ENV["WITHOUT_RAILS"] == "yes"
    t.test_files = Dir['spec/**/*_spec.rb'].reject do |f|
      f.end_with?('_generator_spec.rb') ||
        f.end_with?('input_object_type_spec.rb') ||
        f.end_with?('variables_spec.rb') ||
        f.end_with?('relation_connection_spec.rb') ||
        f.end_with?('node_spec.rb') ||
        f.end_with?('connection_instrumentation_spec.rb') ||
        f.end_with?('graphql/schema_spec.rb') ||
        f.end_with?('graphql/tracing/active_support_notifications_tracing_spec.rb') ||
        f.start_with?('spec/graphql/relay/')
    end
  else
    t.pattern = "spec/**/*_spec.rb"
  end

  t.warning = false
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new

default_tasks = [:test, :rubocop, "js:all"]
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
  assert_dependency_version("Racc", "1.4.14", %|ruby -e "require 'racc'; puts Racc::VERSION"|)

  `rm -f lib/graphql/language/parser.rb lib/graphql/language/lexer.rb `
  `racc lib/graphql/language/parser.y -o lib/graphql/language/parser.rb`
  `ragel -R -F1 lib/graphql/language/lexer.rl`
end

namespace :bench do
  def prepare_benchmark
    $LOAD_PATH << "./lib" << "./spec/support"
    require_relative("./benchmark/run.rb")
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

  desc "Generate a profile of the introspection query"
  task :profile do
    prepare_benchmark
    GraphQLBenchmark.profile
  end
end

namespace :test do
  desc "Run system tests for ActionCable subscriptions"
  task :system do
    success = Dir.chdir("spec/dummy") do
      system("bin/rails test:system")
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

  desc "Publish the package to NPM"
  task :publish do
    Dir.chdir(client_dir) do
      system("npm publish")
    end
  end

  task all: [:install, :test]
end
