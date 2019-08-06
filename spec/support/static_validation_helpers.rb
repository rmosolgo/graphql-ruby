# frozen_string_literal: true
# This module assumes you have `let(:query_string)` in your spec.
# It provides `errors` which are the validation errors for that string,
# as validated against `Dummy::Schema`.
# You can override `schema` to provide another schema
# @example testing static validation
#   include StaticValidationHelpers
#   let(:query_string) { " ... " }
#   it "validates" do
#     assert_equal(errors, [ ... ])
#     assert_equal(error_messages, [ ... ])
#   end
module StaticValidationHelpers
  def errors
    @errors ||= begin
      target_schema = schema
      validator = GraphQL::StaticValidation::Validator.new(schema: target_schema)
      query = GraphQL::Query.new(target_schema, query_string)
      validator.validate(query)[:errors].map(&:to_h)
    end
  end

  def error_messages
    errors.map { |e| e["message"] }
  end

  def schema
    # without #graphql_definition call here #errors / #error_messages will reference a different schema object
    # than the one returned by schema so it's difficult to make changes in specs.
    Dummy::Schema.graphql_definition
  end
end
