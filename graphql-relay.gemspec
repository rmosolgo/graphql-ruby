$LOAD_PATH.push File.expand_path("../lib", __FILE__)

require "graphql/relay/version"

Gem::Specification.new do |s|
  s.name        = 'graphql-relay'
  s.version     = GraphQL::Relay::VERSION
  s.date        = Date.today.to_s
  s.summary     = "Relay helpers for GraphQL"
  s.description = "Define global ids, connections and mutations to use GraphQL and Relay with a Ruby server."
  s.homepage    = 'http://github.com/rmosolgo/graphql-relay-ruby'
  s.authors     = ["Robert Mosolgo"]
  s.email       = ['rdmosolgo@gmail.com']
  s.license     = "MIT"
  s.required_ruby_version = '>= 2.1.0' # bc optional keyword args

  s.files = Dir["{lib}/**/*", "MIT-LICENSE", "readme.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_runtime_dependency "graphql", "~> 0.12"

  s.add_development_dependency "activerecord"
  s.add_development_dependency "appraisal"
  s.add_development_dependency "codeclimate-test-reporter", '~>0.4'
  s.add_development_dependency "pry", "~> 0.10"
  s.add_development_dependency "guard", "~> 2.12"
  s.add_development_dependency "guard-bundler", "~> 2.1"
  s.add_development_dependency "guard-minitest", "~> 2.4"
  s.add_development_dependency "minitest", "~> 5"
  s.add_development_dependency "minitest-focus", "~> 1.1"
  s.add_development_dependency "minitest-reporters", "~>1.0"
  s.add_development_dependency "rake", "~> 11.0"
  s.add_development_dependency "sqlite3"
end
