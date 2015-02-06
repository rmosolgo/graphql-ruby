$:.push File.expand_path("../lib", __FILE__)

require "graphql/version"

Gem::Specification.new do |s|
  s.name        = 'graphql'
  s.version     = GraphQL::VERSION
  s.date        = '2015-01-30'
  s.summary     = "GraphQL"
  s.description = "A GraphQL adapter for Ruby"
  s.homepage    = 'http://github.com/rmosolgo/graphql'
  s.authors     = ["Robert Mosolgo"]
  s.email       = ['rdmosolgo@gmail.com']
  s.license     = "MIT"
  s.required_ruby_version = '>= 2.1.0' # bc keyword args

  s.files = Dir["{lib}/**/*", "MIT-LICENSE", "readme.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "activesupport", ">= 4"
  s.add_dependency "parslet", ">= 1.6.2"

  s.add_development_dependency "guard", ">= 2.1"
  s.add_development_dependency "guard-bundler", ">= 2.1"
  s.add_development_dependency "guard-minitest", ">= 2.1"
  s.add_development_dependency "minitest", ">= 5.5"
  s.add_development_dependency "minitest-focus", ">= 1.1"
  s.add_development_dependency "minitest-reporters", ">= 1.0"
  s.add_development_dependency "rake", ">= 10"
end
