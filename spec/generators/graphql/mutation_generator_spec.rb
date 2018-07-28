# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/mutation_generator"

class GraphQLGeneratorsMutationGeneratorTest < BaseGeneratorTest
  tests Graphql::Generators::MutationGenerator

  destination File.expand_path("../../../tmp/dummy", File.dirname(__FILE__))

  def setup(directory = "app/graphql")
    prepare_destination
    FileUtils.cd(File.expand_path("../../../tmp", File.dirname(__FILE__))) do
      `rm -rf dummy`
      `rails new dummy --skip-active-record --skip-test-unit --skip-spring --skip-bundle`
    end

    FileUtils.cd(destination_root) do
      `rails g graphql:install --directory #{directory}`
    end
  end

  UPDATE_NAME_MUTATION = <<-RUBY
class Mutations::UpdateName < GraphQL::Schema::RelayClassicMutation
  # TODO: define return fields
  # return_field :post, Types::PostType

  # TODO: define arguments
  # input_field :name, !types.String

  def resolve(**inputs)
    # TODO: define resolve method
  end
end
RUBY

  EXPECTED_MUTATION_TYPE = <<-RUBY
class Types::MutationType < Types::BaseObject
  field :updateName, mutation: Mutations::UpdateName
  # TODO: remove me
  field :test_field, String, null: false,
    description: "An example field added by the generator"
  def test_field
    "Hello World"
  end
end
RUBY

  test "it generates an empty resolver by name" do
    setup
    run_generator(["UpdateName"])
    assert_file "app/graphql/mutations/update_name.rb", UPDATE_NAME_MUTATION
  end

  test "it inserts the field into the MutationType" do
    setup
    run_generator(["UpdateName"])
    assert_file "app/graphql/types/mutation_type.rb", EXPECTED_MUTATION_TYPE
  end

  test "it allows for user-specified directory" do
    setup "app/mydirectory"
    run_generator(["UpdateName", "--directory", "app/mydirectory"])

    assert_file "app/mydirectory/mutations/update_name.rb", UPDATE_NAME_MUTATION
  end
end
