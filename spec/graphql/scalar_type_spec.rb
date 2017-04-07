# frozen_string_literal: true
require "spec_helper"

describe GraphQL::ScalarType do
  let(:custom_scalar) {
    GraphQL::ScalarType.define do
      name "BigInt"
      coerce_input ->(value) { value =~ /\d+/ ? Integer(value) : nil }
      coerce_result ->(value) { value.to_s }
    end
  }
  let(:bignum) { 2 ** 128 }

  it "is not a default scalar" do
    assert_equal(false, custom_scalar.default_scalar?)
  end

  it "coerces nil into nil" do
    assert_equal(nil, custom_scalar.coerce_input(nil))
  end

  it "coerces input into objects" do
    assert_equal(bignum, custom_scalar.coerce_input(bignum.to_s))
  end

  it "coerces result value for serialization" do
    assert_equal(bignum.to_s, custom_scalar.coerce_result(bignum))
  end

  describe "when passing literals for scalar types in input objects" do
    let(:scalar_type) {
      GraphQL::ScalarType.define do
        name "ArrayScalar"
        coerce ->(value) { value if value.is_a?(Array) }
      end
    }
    let(:dummy_mutation) {
      scalar_type = scalar_type()
      GraphQL::Relay::Mutation.define do
        name "DummyMutation"
        input_field :input_value, !scalar_type
        return_field :output_value, !scalar_type
        resolve -> (obj, inputs, ctx) { {output_value: inputs[:input_value]} }
      end
    }
    let(:root_object) {
      dummy_mutation = dummy_mutation()
      GraphQL::ObjectType.define do
        name "Mutation"
        field :field, field: dummy_mutation.field
      end
    }
    let(:schema) {
      GraphQL::Schema.define(mutation: root_object)
    }
    let(:query_string) {%|
      mutation M { field(input: {input_value: [1, 2]}) { output_value } }
    |}
    let(:result) {
      schema.execute(query_string)
    }

    it "correctly validates arrays" do
      expected = {"data" => {"field" => {"output_value" => [1, 2]}}}
      assert_equal(expected, result)
    end
  end

  describe "custom scalar errors" do
    let(:result) { custom_scalar.validate_input("xyz", PermissiveWarden) }

    it "returns an invalid result" do
      assert !result.valid?
      assert_equal 'Could not coerce value "xyz" to BigInt', result.problems[0]["explanation"]
    end
  end

  describe "validate_input with good input" do
    let(:result) { GraphQL::INT_TYPE.validate_input(150, PermissiveWarden) }

    it "returns a valid result" do
      assert(result.valid?)
    end
  end

  describe "validate_input with bad input" do
    let(:result) { GraphQL::INT_TYPE.validate_input("bad num", PermissiveWarden) }

    it "returns an invalid result for bad input" do
      assert(!result.valid?)
    end

    it "has one problem" do
      assert_equal(result.problems.length, 1)
    end

    it "has the correct explanation" do
      assert(result.problems[0]["explanation"].include?("Could not coerce value"))
    end

    it "has an empty path" do
      assert(result.problems[0]["path"].empty?)
    end
  end
end
