# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/enum_generator"

class GraphQLGeneratorsEnumGeneratorTest < BaseGeneratorTest
  tests Graphql::Generators::EnumGenerator

  test "it generate enums with values" do
    expected_content = <<-RUBY
class Types::FamilyType < Types::BaseEnum
  value "NIGHTSHADE"
  value "BRASSICA", value: Family::COLE
  value "UMBELLIFER", value: :umbellifer
  value "LEGUME", value: "bean & friends"
  value "CURCURBITS", value: 5
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
