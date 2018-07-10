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
      ["BirdType", "wingspan:Integer!", "foliage:[Types::ColorType]"],
      # Mixed
      ["BirdType", "wingspan:!Int", "foliage:[Color]"],
    ]

    expected_content = <<-RUBY
module Types::BirdType
  include Types::BaseInterface
  field :wingspan, Integer, null: false
  field :foliage, [Types::ColorType], null: true
end
RUBY

    commands.each do |c|
      prepare_destination
      run_generator(c)
      assert_file "app/graphql/types/bird_type.rb", expected_content
    end
  end
end
