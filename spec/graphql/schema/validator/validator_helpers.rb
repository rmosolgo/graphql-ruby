# frozen_string_literal: true

module ValidatorHelpers
  def self.included(child_class)
    child_class.extend(ClassMethods)
  end

  def build_schema(arg_type, validates_config)
    schema = Class.new(GraphQL::Schema)
    query_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "Query"
      field :validated, arg_type, null: true do
        argument :value, arg_type, required: false, validates: validates_config
      end

      def validated(value:)
        value
      end
    end
    schema.query(query_type)
    schema
  end

  module ClassMethods
    def build_tests(validator_name, field_type, expectations)
      expectations.each do |expectation|
        it "#{validator_name} on #{field_type} works with #{expectation[:config]}" do
          schema = build_schema(field_type, { validator_name => expectation[:config] })
          expectation[:cases].each do |test_case|
            result = schema.execute(test_case[:query])
            if test_case[:result].nil?
              assert_nil result["data"]["validated"]
            else
              assert_equal test_case[:result], result["data"]["validated"]
            end
            assert_equal test_case[:error_messages], (result["errors"] || []).map { |e| e["message"] }
          end
        end
      end
    end
  end
end

