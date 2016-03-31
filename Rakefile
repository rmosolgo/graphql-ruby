require 'bundler/setup'
Bundler::GemHelper.install_tasks

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "spec" << "lib"
  t.pattern = "spec/**/*_spec.rb"
  t.warning = false
end

task(default: :test)

def load_gem_and_dummy
  $:.push File.expand_path("../lib", __FILE__)
  $:.push File.expand_path("../spec", __FILE__)
  require 'graphql'
  require './spec/support/dairy_app'
end

task :repl do
  load_gem_and_dummy
  ARGV.clear
  repl = GraphQL::Repl.new(DummySchema)
  repl.run
end

task :console do
  require 'irb'
  require 'irb/completion'
  load_gem_and_dummy
  ARGV.clear
  IRB.start
end
