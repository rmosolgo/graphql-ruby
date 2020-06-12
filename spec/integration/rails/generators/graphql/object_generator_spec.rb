# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/object_generator"

class GraphQLGeneratorsObjectGeneratorTest < BaseGeneratorTest
  tests Graphql::Generators::ObjectGenerator

  ActiveRecord::Schema.define do
    create_table :test_users do |t|
      t.datetime :created_at
      t.date :birthday
      t.integer :points, null: false
    end
  end

  # rubocop:disable Style/ClassAndModuleChildren
  class ::TestUser < ActiveRecord::Base
  end
  # rubocop:enable Style/ClassAndModuleChildren

  test "it generates fields with types" do
    commands = [
      # GraphQL-style:
      ["Bird", "wingspan:Int!", "foliage:[Color]"],
      # Ruby-style:
      ["BirdType", "wingspan:!Integer", "foliage:[Types::ColorType]"],
      # Mixed
      ["BirdType", "wingspan:!Int", "foliage:[Color]"],
    ]

    expected_content = <<-RUBY
module Types
  class BirdType < Types::BaseObject
    field :wingspan, Integer, null: false
    field :foliage, [Types::ColorType], null: true
  end
end
RUBY

    commands.each do |c|
      prepare_destination
      run_generator(c)
      assert_file "app/graphql/types/bird_type.rb", expected_content
    end
  end

  test "it generates classifed file" do
    run_generator(["page"])
    assert_file "app/graphql/types/page_type.rb", <<-RUBY
module Types
  class PageType < Types::BaseObject
  end
end
RUBY
  end

  test "it makes Relay nodes" do
    run_generator(["Page", "--node"])
    assert_file "app/graphql/types/page_type.rb", <<-RUBY
module Types
  class PageType < Types::BaseObject
    implements GraphQL::Relay::Node.interface
  end
end
RUBY
  end

  test "it generates objects based on ActiveRecord schema" do
    run_generator(["TestUser"])
    assert_file "app/graphql/types/test_user_type.rb", <<-RUBY
module Types
  class TestUserType < Types::BaseObject
    field :id, ID, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: true
    field :birthday, GraphQL::Types::ISO8601Date, null: true
    field :points, Integer, null: false
  end
end
RUBY
  end

  test "it generates objects based on ActiveRecord schema with additional custom fields" do
    run_generator(["TestUser", "name:!String"])
    assert_file "app/graphql/types/test_user_type.rb", <<-RUBY
module Types
  class TestUserType < Types::BaseObject
    field :id, ID, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: true
    field :birthday, GraphQL::Types::ISO8601Date, null: true
    field :points, Integer, null: false
    field :name, String, null: false
  end
end
RUBY
  end
end
