# frozen_string_literal: true
require "spec_helper"
require "open3"

describe GraphQL do
  it "loads without warnings" do
    stderr_and_stdout, _status = Open3.capture2e(%|ruby -Ilib -e "require 'bundler/inline'; gemfile(true, quiet: true) { source('https://rubygems.org'); gem('fiber-storage'); gem('graphql', path: './') }; GraphQL.eager_load!"|)
    assert_equal "", stderr_and_stdout
  end


  it "loads without warnings when Rails is defined but `Rails.env` isn't" do
    script = <<~RUBY
      require 'bundler/inline'
      module Rails
      end

      gemfile(true, quiet: true) do
        source('https://rubygems.org')
        gem 'graphql'
        gem 'fiber-storage'
      end

      class MySchema < GraphQL::Schema
        use GraphQL::Schema::AlwaysVisible
      end

      GraphQL.eager_load!
    RUBY

    stderr_and_stdout, _status = Open3.capture2e(%|ruby -Ilib -e "#{script}"|)
    assert_equal "", stderr_and_stdout
  end
end
