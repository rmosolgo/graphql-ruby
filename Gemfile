# frozen_string_literal: true
source "https://rubygems.org"

gemspec

gem 'bootsnap' # required by the Rails apps generated in tests
gem 'stackprof', platform: :ruby
gem 'pry'
gem 'pry-stack_explorer', platform: :ruby
gem 'graphql-batch'
gem 'pry-byebug'

# For Ruby 3.2 compat:
gem "yard", github: "lsegal/yard", ref: "b51bf26"

if RUBY_VERSION >= "3.0"
  gem "libev_scheduler"
  gem "evt"
end

if RUBY_PLATFORM.include?("linux")
  gem "ruby_memcheck"
end

# Required for running `jekyll algolia ...` (via `rake site:update_search_index`)
group :jekyll_plugins do
  gem 'jekyll-algolia', '~> 1.0'
  gem 'jekyll-redirect-from'
end
