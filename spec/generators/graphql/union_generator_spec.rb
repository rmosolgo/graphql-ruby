# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/union_generator"

class GraphQLGeneratorsUnionGeneratorTest < BaseGeneratorTest
  tests Graphql::Generators::UnionGenerator

  test "it generates a union with possible types" do
    commands = [
      # GraphQL-style:
      ["WingedCreature", "Insect", "Bird"],
      # Ruby-style:
      ["Types::WingedCreatureType", "Types::InsectType", "Types::BirdType"],
    ]

    expected_content = <<-RUBY
Types::WingedCreatureType = GraphQL::UnionType.define do
  name "WingedCreature"
  possible_types [Types::InsectType, Types::BirdType]
end
RUBY

    commands.each do |c|
      prepare_destination
      run_generator(c)
      assert_file "app/graphql/types/winged_creature_type.rb", expected_content
    end
  end

  test "it works with no possible types" do
    commands = [
      # GraphQL-style:
      ["WingedCreature"],
      # Ruby-style:
      ["Types::WingedCreatureType"],
    ]

    expected_content = <<-RUBY
Types::WingedCreatureType = GraphQL::UnionType.define do
  name "WingedCreature"
end
RUBY

    commands.each do |c|
      prepare_destination
      run_generator(c)
      assert_file "app/graphql/types/winged_creature_type.rb", expected_content
    end
  end
end
