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

group :docs, optional: true do
  gem "rdoc", "~> 7.2"
end
