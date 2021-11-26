# frozen_string_literal: true
$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "graphql/version"
require "date"

Gem::Specification.new do |s|
  s.name        = "graphql"
  s.version     = GraphQL::VERSION
  s.date        = Date.today.to_s
  s.summary     = "A GraphQL language and runtime for Ruby"
  s.description = "A plain-Ruby implementation of GraphQL."
  s.homepage    = "https://github.com/rmosolgo/graphql-ruby"
  s.authors     = ["Robert Mosolgo"]
  s.email       = ["rdmosolgo@gmail.com"]
  s.license     = "MIT"
  s.required_ruby_version = ">= 2.4.0"
  s.metadata    = {
    "homepage_uri" => "https://graphql-ruby.org",
    "changelog_uri" => "https://github.com/rmosolgo/graphql-ruby/blob/master/CHANGELOG.md",
    "source_code_uri" => "https://github.com/rmosolgo/graphql-ruby",
    "bug_tracker_uri" => "https://github.com/rmosolgo/graphql-ruby/issues",
    "mailing_list_uri"  => "https://tinyletter.com/graphql-ruby",
  }

  s.files = Dir["{lib}/**/*", "MIT-LICENSE", "readme.md", ".yardopts"]

  s.add_development_dependency "benchmark-ips"
  s.add_development_dependency "concurrent-ruby", "~>1.0"
  s.add_development_dependency "memory_profiler"
  # Remove this limit when minitest-reports is compatible
  # https://github.com/kern/minitest-reporters/pull/220
  s.add_development_dependency "minitest", "~> 5.9.0"
  s.add_development_dependency "minitest-focus", "~> 1.1"
  s.add_development_dependency "minitest-reporters", "~>1.0"
  s.add_development_dependency "racc", "~> 1.4"
  s.add_development_dependency "rake", "~> 12"
  s.add_development_dependency "rubocop", "1.12" # for Ruby 2.4 enforcement
  # website stuff
  s.add_development_dependency "jekyll"
  s.add_development_dependency "yard"
  s.add_development_dependency "jekyll-algolia"
  s.add_development_dependency "jekyll-redirect-from"
  s.add_development_dependency "m", "~> 1.5.0"
  s.add_development_dependency "webrick"
end
