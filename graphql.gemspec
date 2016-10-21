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
  s.required_ruby_version = ">= 1.9.3" # Unofficial support

  s.files = Dir["{lib}/**/*", "MIT-LICENSE", "readme.md", ".yardopts"]
  s.test_files = Dir["spec/**/*"]

  ### Disable for unofficial Ruby 1.9.3 support as one of its deps (json) is only compatible with Ruby 2.0+.
  # s.add_development_dependency "codeclimate-test-reporter", "~>0.4"
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
  s.add_development_dependency "rubocop", "< 0.42"
  # following are required for relay helpers
  s.add_development_dependency "activerecord", "< 5"
  s.add_development_dependency "appraisal"
  s.add_development_dependency "sequel"
  s.add_development_dependency "sqlite3"
  ### Disable for unofficial Ruby 1.9.3 support as one of these is only compatible with Ruby 2.0+.
  # website stuff
  # s.add_development_dependency "github-pages"
  # s.add_development_dependency "html-proofer"
end
