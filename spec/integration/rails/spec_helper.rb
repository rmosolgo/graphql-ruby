# frozen_string_literal: true
require "rake"
require "rails/all"
require "rails/generators"
require "sequel"

if ENV['DATABASE'] == 'POSTGRESQL'
  require 'pg'
else
  require "jdbc/sqlite3" if RUBY_ENGINE == 'jruby'
  require "sqlite3" if RUBY_ENGINE == 'ruby'
end

require_relative "generators/base_generator_test"
require_relative "data"

def with_active_record_log
  io = StringIO.new
  prev_logger = ActiveRecord::Base.logger
  ActiveRecord::Base.logger = Logger.new(io)
  yield
  io.string
ensure
  ActiveRecord::Base.logger = prev_logger
end

if ActiveSupport.respond_to?(:test_order=)
  ActiveSupport.test_order = :random
end
