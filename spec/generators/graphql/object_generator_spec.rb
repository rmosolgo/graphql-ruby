# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/object_generator"

class GraphQLGeneratorsObjectGeneratorTest < BaseGeneratorTest
  tests Graphql::Generators::ObjectGenerator

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
Types::BirdType = GraphQL::ObjectType.define do
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

  test "it generates classifed file" do
    run_generator(["page"])
    assert_file "app/graphql/types/page_type.rb", <<-RUBY
Types::PageType = GraphQL::ObjectType.define do
  name "Page"
end
RUBY
  end

  test "it makes Relay nodes" do
    run_generator(["Page", "--node"])
    assert_file "app/graphql/types/page_type.rb", <<-RUBY
Types::PageType = GraphQL::ObjectType.define do
  name "Page"
  implements GraphQL::Relay::Node.interface
end
RUBY
  end
end
