# frozen_string_literal: true
source "https://rubygems.org"

gemspec

gem 'bootsnap' # required by the Rails apps generated in tests
gem 'stackprof', platform: :ruby
gem 'pry'
gem 'pry-stack_explorer', platform: :ruby

if RUBY_VERSION >= "3.2.0"
  gem "async", "~>2.0"
  gem "minitest-mock"
end

# Required for running `jekyll algolia ...` (via `rake site:update_search_index`)
group :jekyll_plugins do
  gem 'jekyll-algolia', '~> 1.0'
  gem 'jekyll-redirect-from'
end
