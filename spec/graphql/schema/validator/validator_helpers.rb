# frozen_string_literal: true

module ValidatorHelpers
  def self.included(child_class)
    child_class.extend(ClassMethods)
  end

  def build_schema(arg_type, validates_config)
    schema = Class.new(GraphQL::Schema)

    validated_input = Class.new(GraphQL::Schema::InputObject) do
      graphql_name "ValidatedInput"
      argument :a, arg_type, required: false
      argument :b, arg_type, required: false
      argument :c, arg_type, required: false
      validates(validates_config)
    end

    validated_resolver = Class.new(GraphQL::Schema::Resolver) do
      argument :a, arg_type, required: false
      argument :b, arg_type, required: false
      argument :c, arg_type, required: false
      validates(validates_config)
      type(arg_type, null: true)
      def resolve(a: 0, b: 0, c: 0)
        a + b + c
      end
    end

    query_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "Query"
      field :validated, arg_type, null: true do
        argument :value, arg_type, required: false, validates: validates_config
      end

      def validated(value:)
        value
      end

      field :multi_validated, arg_type, null: true, validates: validates_config do
        argument :a, arg_type, required: false
        argument :b, arg_type, required: false
        argument :c, arg_type, required: false
      end

      def multi_validated(a: 0, b: 0, c: 0)
        a + b + c
      end

      field :validated_input, arg_type, null: true do
        argument :input, validated_input, required: true
      end

      def validated_input(input:)
        (input[:a] || 0) + (input[:b] || 0) + (input[:c] || 0)
      end

      field :validated_resolver, resolver: validated_resolver
    end

    schema.query(query_type)
    schema
  end

  module ClassMethods
    def build_tests(validator_name, field_type, expectations)
      expectations.each do |expectation|
        name = expectation[:name] ? "#{expectation[:name]}: " : ""
        it "#{name}#{validator_name} on #{field_type} works with #{expectation[:config]}" do
          schema = build_schema(field_type, { validator_name => expectation[:config] })
          expectation[:cases].each do |test_case|
            result = schema.execute(test_case[:query])
            if !result["data"]
              pp result
              refute result["errors"].map { |e| e["message"] }, test_case[:query]
            end

            assert_equal test_case[:error_messages], (result["errors"] || []).map { |e| e["message"] }, test_case[:query]

            if test_case[:result].nil?
              assert_nil result["data"]["validated"], test_case[:query]
            else
              assert_equal test_case[:result], result["data"]["validated"], test_case[:query]
            end
          end
        end
      end
    end
  end
end

