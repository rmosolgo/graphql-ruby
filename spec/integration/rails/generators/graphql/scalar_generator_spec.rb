# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/scalar_generator"

class GraphQLGeneratorsScalarGeneratorTest < BaseGeneratorTest
  tests Graphql::Generators::ScalarGenerator

  test "it generates scalar class" do
    expected_content = <<-RUBY
module Types
  class DateType < Types::BaseScalar
    def self.coerce_input(input_value, context)
      # TODO: implement me
      raise NotImplementedError
    end

    def self.coerce_result(ruby_value, context)
      # TODO: implement me
      raise NotImplementedError
    end
  end
end
RUBY

    run_generator(["Date"])
    assert_file "app/graphql/types/date_type.rb", expected_content
  end
end
