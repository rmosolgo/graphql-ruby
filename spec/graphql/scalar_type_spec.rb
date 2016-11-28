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

  it "coerces nil into nil" do
    assert_equal(nil, custom_scalar.coerce_input(nil))
  end

  it "coerces input into objects" do
    assert_equal(bignum, custom_scalar.coerce_input(bignum.to_s))
  end

  it "coerces result value for serialization" do
    assert_equal(bignum.to_s, custom_scalar.coerce_result(bignum))
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
