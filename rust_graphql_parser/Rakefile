# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

require "rake/extensiontask"

task build: :compile

Rake::ExtensionTask.new("rust_graphql_parser") do |ext|
  ext.lib_dir = "lib/rust_graphql_parser"
end

task default: %i[compile spec rubocop]
