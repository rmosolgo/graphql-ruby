# frozen_string_literal: true
require "bundler/setup"
Bundler::GemHelper.install_tasks

require "rake/testtask"
require_relative "guides/_tasks/site"

Rake::TestTask.new do |t|
  t.libs << "spec" << "lib"

  if defined?(Rails)
    t.pattern = "spec/**/*_spec.rb"
  else
    t.test_files = Dir['spec/**/*_spec.rb'].reject do |f|

      f.end_with?('_generator_spec.rb') ||
        f.end_with?('input_object_type_spec.rb') ||
        f.end_with?('variables_spec.rb') ||
        f.end_with?('relation_connection_spec.rb') ||
        f.end_with?('node_spec.rb') ||
        f.end_with?('connection_instrumentation_spec.rb') ||
        f.end_with?('graphql/schema_spec.rb') ||
        f.start_with?('spec/graphql/relay/')
    end
  end

  t.warning = false
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new

task(default: [:test, :rubocop])

desc "Use Racc & Ragel to regenerate parser.rb & lexer.rb from configuration files"
task :build_parser do
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
