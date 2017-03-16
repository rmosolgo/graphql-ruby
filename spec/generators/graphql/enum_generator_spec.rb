# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/enum_generator"

class GraphQLGeneratorsEnumGeneratorTest < BaseGeneratorTest
  tests Graphql::Generators::EnumGenerator

  test "it generate enums with values" do
    expected_content = <<-RUBY
Types::FamilyType = GraphQL::EnumType.define do
  name "Family"
  value "NIGHTSHADE"
  value "BRASSICA", Family::COLE
  value "UMBELLIFER", :umbellifer
  value "LEGUME", "bean & friends"
  value "CURCURBITS", 5
end
RUBY

    run_generator(["Family",
      "NIGHTSHADE",
      "BRASSICA:Family::COLE",
      "UMBELLIFER::umbellifer",
      'LEGUME:"bean & friends"',
      "CURCURBITS:5"
    ])
    assert_file "app/graphql/types/family_type.rb", expected_content
  end
end
