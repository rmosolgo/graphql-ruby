# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/mutation_update_generator"

class GraphQLGeneratorsMutationUpdateGeneratorTest < BaseGeneratorTest
  tests Graphql::Generators::MutationUpdateGenerator

  destination File.expand_path("../../../tmp/dummy", File.dirname(__FILE__))

  def setup(directory = "app/graphql")
    prepare_destination
    FileUtils.cd(File.expand_path("../../../tmp", File.dirname(__FILE__))) do
      `rm -rf dummy`
      `rails new dummy --skip-active-record --skip-test-unit --skip-spring --skip-bundle --skip-webpack-install --skip-action-mailer --skip-action-mailbox --skip-collision-check --skip-puma --skip-sprockets --skip-spring`
      # TODO: If the rails gem is 6.1+, test the --minimal option
      # `rails new dummy --minimal --skip-bundle`
    end

    FileUtils.cd(destination_root) do
      `mkdir #{directory}`
      `touch #{directory}/dummy_schema.rb`
    end
  end

  NAMESPACED_UPDATE_NAME_MUTATION = <<-RUBY
# frozen_string_literal: true

module Mutations
  class Names::NameUpdate < BaseMutation
    description "Updates a name by id"

    field :name, Types::Objects::Names::NameType, null: false

    argument :id, ID, required: true
    argument :name_input, Types::Inputs::Names::NameInputType, required: true

    def resolve(id:, name_input:)
      names_name = Names::Name.find(id)
      raise GraphQL::ExecutionError.new "Error updating name", extensions: names_name.errors.to_h unless names_name.update(**name_input)

      { name: names_name }
    end
  end
end
RUBY

  UPDATE_NAME_MUTATION = <<-RUBY
# frozen_string_literal: true

module Mutations
  class Names::NameUpdate < BaseMutation
    description "Updates a name by id"

    field :name, Types::Names::NameType, null: false

    argument :id, ID, required: true
    argument :name_input, Types::Names::NameInputType, required: true

    def resolve(id:, name_input:)
      names_name = Names::Name.find(id)
      raise GraphQL::ExecutionError.new "Error updating name", extensions: names_name.errors.to_h unless names_name.update(**name_input)

      { name: names_name }
    end
  end
end
RUBY

  EXPECTED_UPDATE_MUTATION_TYPE = <<-RUBY
module Types
  class MutationType < Types::BaseObject
    field :name_update, mutation: Mutations::Names::NameUpdate
    # TODO: remove me
    field :test_field, String, null: false,
      description: "An example field added by the generator"
    def test_field
      "Hello World"
    end
  end
end
RUBY

  test "it generates an update resolver by name, and inserts the field into the MutationType" do
    setup
    run_generator(["names/name"])
    assert_file "app/graphql/mutations/names/name_update.rb", UPDATE_NAME_MUTATION
    assert_file "app/graphql/types/mutation_type.rb", EXPECTED_UPDATE_MUTATION_TYPE
  end

  test "it generates a namespaced update resolver by name" do
    setup
    run_generator(["names/name", "--namespaced-types"])
    assert_file "app/graphql/mutations/names/name_update.rb", NAMESPACED_UPDATE_NAME_MUTATION
  end

  test "it allows for user-specified directory, update" do
    setup "app/mydirectory"
    run_generator(["names/name", "--directory", "app/mydirectory"])

    assert_file "app/mydirectory/mutations/names/name_update.rb", UPDATE_NAME_MUTATION
  end
end
