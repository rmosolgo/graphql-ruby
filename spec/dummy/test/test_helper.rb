# frozen_string_literal: true
TESTING_INTERPRETER = !!ENV["TESTING_INTERPRETER"]
TESTING_AST_ANALYSIS = !!ENV["TESTING_AST_ANALYSIS"]
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
