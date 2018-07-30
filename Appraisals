# frozen_string_literal: true
appraise 'rails_3.2' do
  gem "rails", "3.2.22.5"
  gem 'activerecord', '~> 3.2.21'
  gem 'actionpack', '~> 3.2.21'
  gem 'test-unit'
end

appraise 'rails_4.1' do
  gem "rails", "~> 4.1"
  gem 'activerecord', '~> 4.1.10'
  gem 'actionpack', '~> 4.1.10'
  gem 'test-unit'
end

appraise 'rails_4.2' do
  gem "rails", "~> 4.2"
  gem 'activerecord', '~> 4.2.4'
  gem 'actionpack', '~> 4.2.4'
  gem 'concurrent-ruby', '1.0.0'
end

appraise 'rails_5.0' do
  gem "rails", "~> 5.0"
  gem 'activerecord', '~> 5.0.0'
  gem 'actionpack', '~> 5.0.0'
end

appraise 'rails_5.1' do
  gem 'rails', '~> 5.1.0'
  # Required for testing action cable
  gem 'puma'
  # Required for system tests
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'
end

appraise "rails_5.2" do
  gem 'rails', '~> 5.2.0'
end

appraise 'without_rails' do
  gem "globalid"
end
