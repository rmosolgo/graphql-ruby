$LOAD_PATH.push File.expand_path("../lib", __FILE__)

require "graphql/version"

Gem::Specification.new do |s|
  s.name        = "graphql"
  s.version     = GraphQL::VERSION
  s.date        = Date.today.to_s
  s.summary     = "A GraphQL server implementation for Ruby"
  s.description = "A GraphQL server implementation for Ruby. Includes schema definition, query parsing, static validation, type definition, and query execution."
  s.homepage    = "http://github.com/rmosolgo/graphql-ruby"
  s.authors     = ["Robert Mosolgo"]
  s.email       = ["rdmosolgo@gmail.com"]
  s.license     = "MIT"
  s.required_ruby_version = ">= 2.1.0" # bc optional keyword args

  s.files = Dir["{lib}/**/*", "MIT-LICENSE", "readme.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_development_dependency "codeclimate-test-reporter", "~>0.4"
  s.add_development_dependency "pry", "~> 0.10"
  s.add_development_dependency "guard", "~> 2.12"
  s.add_development_dependency "guard-bundler", "~> 2.1"
  s.add_development_dependency "guard-minitest", "~> 2.4"
  s.add_development_dependency "guard-rake"
  s.add_development_dependency "listen", "~> 3.0.0"
  s.add_development_dependency "minitest", "~> 5"
  s.add_development_dependency "minitest-focus", "~> 1.1"
  s.add_development_dependency "minitest-reporters", "~>1.0"
  s.add_development_dependency "racc", "~> 1.4"
  s.add_development_dependency "rake", "~> 11.0"
  # following are required for relay helpers
  s.add_development_dependency "activerecord"
  s.add_development_dependency "appraisal"
  s.add_development_dependency "sequel"
  s.add_development_dependency "sqlite3"
  # website development
  s.add_development_dependency "adsf"
  s.add_development_dependency "nanoc"
  s.add_development_dependency "redcarpet"
  s.add_development_dependency "rouge"
  s.add_development_dependency "html-proofer"
end
