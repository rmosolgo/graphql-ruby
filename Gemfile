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

# Website tasks opt in to these dependencies via BUNDLE_WITH=jekyll_plugins.
group :jekyll_plugins, optional: true do
  gem 'jekyll'
  gem 'jekyll-sass-converter', '~> 2.2'
  gem 'jekyll-algolia', '~> 1.0'
  gem 'jekyll-redirect-from'
end
