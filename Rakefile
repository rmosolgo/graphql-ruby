require 'bundler/setup'
Bundler::GemHelper.install_tasks

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "spec" << "lib"
  t.pattern = "spec/**/*_spec.rb"
end

task(default: :test)

task :repl do
  $:.push File.expand_path("../lib", __FILE__)
  $:.push File.expand_path("../spec", __FILE__)
  require 'graphql'
  require './spec/support/dummy_app'
  ARGV.clear
  repl = GraphQL::Repl.new(DummySchema)
  repl.run
end
