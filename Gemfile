# frozen_string_literal: true
source "https://rubygems.org"

gemspec

gem 'bootsnap' # required by the Rails apps generated in tests
gem 'ruby-prof', platform: :ruby
gem 'pry'
gem 'pry-stack_explorer', platform: :ruby
gem 'graphql-batch'
if RUBY_VERSION >= "2.4"
  gem 'pry-byebug'
end

# Required for running `jekyll algolia ...` (via `rake site:update_search_index`)
group :jekyll_plugins do
  if RUBY_VERSION >= "2.3"
    gem 'jekyll-algolia', '~> 1.0'
  end
  gem 'jekyll-redirect-from'
end
