# This module assumes you have `let(:query_string)` in your spec.
# It provides `errors` which are the validation errors for that string,
# as validated against `DummySchema`.
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
    target_schema = schema
    validator = GraphQL::StaticValidation::Validator.new(schema: target_schema)
    document = GraphQL.parse(query_string)
    visitor = GraphQL::Language::Visitor.new(document)
    analysis = GraphQL::StaticAnalysis.prepare(visitor, schema: target_schema)
    visitor.visit
    analysis.errors.map(&:to_h)
  end

  def error_messages
    errors.map { |e| e["message"] }
  end

  def schema
    DummySchema
  end
end
