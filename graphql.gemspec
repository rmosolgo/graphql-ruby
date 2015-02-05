$:.push File.expand_path("../lib", __FILE__)

require "graphql"

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

  s.files = Dir["{lib}/**/*", "MIT-LICENSE", "readme.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "activesupport", ">= 4"
  s.add_dependency "parslet", ">= 1.6.2"

  s.add_development_dependency "guard"
  s.add_development_dependency "guard-bundler"
  s.add_development_dependency "guard-minitest"
  s.add_development_dependency "minitest"
  s.add_development_dependency "minitest-focus"
  s.add_development_dependency "minitest-reporters"
end
