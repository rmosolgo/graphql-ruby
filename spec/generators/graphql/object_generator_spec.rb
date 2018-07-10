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
      ["BirdType", "wingspan:!Integer", "foliage:[Types::ColorType]"],
      # Mixed
      ["BirdType", "wingspan:!Int", "foliage:[Color]"],
    ]

    expected_content = <<-RUBY
class Types::BirdType < Types::BaseObject
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

  test "it generates classifed file" do
    run_generator(["page"])
    assert_file "app/graphql/types/page_type.rb", <<-RUBY
class Types::PageType < Types::BaseObject
end
RUBY
  end

  test "it makes Relay nodes" do
    run_generator(["Page", "--node"])
    assert_file "app/graphql/types/page_type.rb", <<-RUBY
class Types::PageType < Types::BaseObject
  implements GraphQL::Relay::Node.interface
end
RUBY
  end
end
