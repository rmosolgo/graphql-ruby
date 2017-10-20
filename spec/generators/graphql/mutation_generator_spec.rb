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

  test "it generates an empty resolver by name" do
    setup
    run_generator(["UpdateName"])

    expected_content = <<-RUBY
Mutations::UpdateName = GraphQL::Relay::Mutation.define do
  name "UpdateName"
  # TODO: define return fields
  # return_field :post, Types::PostType

  # TODO: define arguments
  # input_field :name, !types.String

  resolve ->(obj, args, ctx) {
    # TODO: define resolve function
  }
end
RUBY

    assert_file "app/graphql/mutations/update_name.rb", expected_content
  end

  test "it allows for user-specified directory" do
    setup "app/mydirectory"
    run_generator(["UpdateName", "--directory", "app/mydirectory"])

    expected_content = <<-RUBY
Mutations::UpdateName = GraphQL::Relay::Mutation.define do
  name "UpdateName"
  # TODO: define return fields
  # return_field :post, Types::PostType

  # TODO: define arguments
  # input_field :name, !types.String

  resolve ->(obj, args, ctx) {
    # TODO: define resolve function
  }
end
RUBY

    assert_file "app/mydirectory/mutations/update_name.rb", expected_content
  end
end
