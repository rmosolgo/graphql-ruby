# frozen_string_literal: true
require File.expand_path('../../config/environment', __FILE__)
# Load mounted route helpers before ActionDispatch::IntegrationTest includes them.
Rails.application.reload_routes_unless_loaded
require 'rails/test_help'
