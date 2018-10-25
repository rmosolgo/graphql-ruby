# frozen_string_literal: true
source "https://rubygems.org"

gemspec

gem 'bootsnap' # required by the Rails apps generated in tests
gem 'ruby-prof', platform: :ruby
gem 'pry'
gem 'pry-stack_explorer', platform: :ruby

# Required for running `jekyll algolia ...` (via `rake site:update_search_index`)
group :jekyll_plugins do
  gem 'jekyll-algolia', '~> 1.0'
end
