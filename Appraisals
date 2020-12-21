# frozen_string_literal: true
appraise 'rails_3.2' do
  gem 'rails', '3.2.22.5', require: 'rails/all'
  gem 'activerecord', '~> 3.2.21'
  gem 'actionpack', '~> 3.2.21'
  gem 'test-unit'
  gem 'sqlite3', "~> 1.3.6", platform: :ruby
  gem 'activerecord-jdbcsqlite3-adapter', platform: :jruby
  gem 'sequel'
end

appraise 'rails_4.2' do
  gem 'rails', '~> 4.2', require: 'rails/all'
  gem 'activerecord', '~> 4.2.4'
  gem 'actionpack', '~> 4.2.4'
  gem 'concurrent-ruby', '1.0.0'
  gem 'sqlite3', "~> 1.3.6", platform: :ruby
  gem 'activerecord-jdbcsqlite3-adapter', platform: :jruby
  gem 'sequel'
end

appraise 'rails_5.2_postgresql' do
  gem 'rails', '~> 5.2.0', require: 'rails/all'
  gem 'pg', platform: :ruby
  gem 'sequel'
end

appraise 'rails_6.0' do
  gem 'rails', '~> 6.0.0', require: 'rails/all'
  gem 'sqlite3', "~> 1.4", platform: :ruby
  gem 'activerecord-jdbcsqlite3-adapter', platform: :jruby
  gem 'sequel'
end

appraise 'rails_master' do
  gem 'rails', github: 'rails/rails', require: 'rails/all'
  gem 'sqlite3', "~> 1.4", platform: :ruby
  gem 'activerecord-jdbcsqlite3-adapter', platform: :jruby
  gem 'sequel'
end

appraise 'mongoid_7' do
  gem 'mongoid', '~> 7.0.1'
end

appraise 'mongoid_6' do
  gem 'mongoid', '~> 6.4.1'
end
