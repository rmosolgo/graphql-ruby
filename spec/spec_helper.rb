require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
require 'graphql'
require "benchmark"
require "minitest/autorun"
require "minitest/focus"
require "minitest/reporters"
require 'pry'
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# # Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

require 'parslet'
require 'parslet/convenience'
