# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/function_generator"

class GraphQLGeneratorsFunctionGeneratorTest < BaseGeneratorTest
  tests Graphql::Generators::FunctionGenerator

  test "it generates an empty function by name" do
    run_generator(["FindRecord"])

    expected_content = <<-RUBY
class Functions::FindRecord < GraphQL::Function
  # Define `initialize` to store field-level options, eg
  #
  #     field :myField, function: Functions::FindRecord.new(type: MyType)
  #
  # attr_reader :type
  # def initialize(type:)
  #   @type = type
  # end

  # add arguments by type:
  # argument :id, !types.ID

  # Resolve function:
  def call(obj, args, ctx)
  end
end
RUBY

    assert_file "app/graphql/functions/find_record.rb", expected_content
  end
end
