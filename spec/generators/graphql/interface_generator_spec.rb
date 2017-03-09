# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/interface_generator"

class GraphQLGeneratorsInterfaceGeneratorTest < BaseGeneratorTest
  tests Graphql::Generators::InterfaceGenerator

  test "it generates fields with types" do
    commands = [
      # GraphQL-style:
      ["Bird", "wingspan:Int!", "foliage:[Color]"],
      # Ruby-style:
      ["BirdType", "wingspan:!types.Int", "foliage:types[Types::ColorType]"],
      # Mixed
      ["BirdType", "wingspan:!Int", "foliage:types[Color]"],
    ]

    expected_content = <<-RUBY
Types::BirdType = GraphQL::InterfaceType.define do
  name "Bird"
  field :wingspan, !types.Int
  field :foliage, types[Types::ColorType]
end
RUBY

    commands.each do |c|
      prepare_destination
      run_generator(c)
      assert_file "app/graphql/types/bird_type.rb", expected_content
    end
  end
end
