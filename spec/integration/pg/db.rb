# frozen_string_literal: true

require_relative 'spec_helper'

ActiveRecord::Base.establish_connection(
  adapter: "postgresql",
  username: "postgres",
  database: "graphql_ruby_test"
)

Sequel.connect('postgres://postgres:@localhost:5432/graphql_ruby_test')
