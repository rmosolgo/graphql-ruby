# frozen_string_literal: true
require "rake"
require "rails/all"
require "rails/generators"
require "sequel"

require "jdbc/sqlite3" if RUBY_ENGINE == 'jruby'
require "sqlite3" if RUBY_ENGINE == 'ruby'

require_relative "generators/base_generator_test"
require_relative "data"
