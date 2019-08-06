# frozen_string_literal: true
require "spec_helper"

describe GraphQL::ScalarType do
  let(:custom_scalar) {
    GraphQL::ScalarType.define do
      name "BigInt"
      coerce_input ->(value, _ctx) { value =~ /\d+/ ? Integer(value) : nil }
      coerce_result ->(value, _ctx) { value.to_s }
    end
  }
  let(:bignum) { 2 ** 128 }

  it "is not a default scalar" do
    assert_equal(false, custom_scalar.default_scalar?)
  end

  it "coerces nil into nil" do
    assert_equal(nil, custom_scalar.coerce_isolated_input(nil))
  end

  it "coerces input into objects" do
    assert_equal(bignum, custom_scalar.coerce_isolated_input(bignum.to_s))
  end

  it "coerces result value for serialization" do
    assert_equal(bignum.to_s, custom_scalar.coerce_isolated_result(bignum))
  end

  describe "custom scalar errors" do
    let(:result) { custom_scalar.validate_isolated_input("xyz") }

    it "returns an invalid result" do
      assert !result.valid?
      assert_equal 'Could not coerce value "xyz" to BigInt', result.problems[0]["explanation"]
    end
  end

  describe "validate_input with good input" do
    let(:result) { GraphQL::INT_TYPE.validate_isolated_input(150) }

    it "returns a valid result" do
      assert(result.valid?)
    end
  end

  describe "validate_input with bad input" do
    let(:result) { GraphQL::INT_TYPE.validate_isolated_input("bad num") }

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
