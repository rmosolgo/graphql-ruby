require 'spec_helper'

describe GraphQL::ScalarType do
  let(:scalar) {
    GraphQL::ScalarType.define do
      name "BigInt"
      coerce_input ->(value) { Integer(value) }
      coerce_result ->(value) { value.to_s }
    end
  }
  let(:bignum) { 2 ** 128 }

  it 'coerces nil into nil' do
    assert_equal(nil, scalar.coerce_input(nil))
  end

  it 'coerces input into objects' do
    assert_equal(bignum, scalar.coerce_input(bignum.to_s))
  end

  it 'coerces result value for serialization' do
    assert_equal(bignum.to_s, scalar.coerce_result(bignum))
  end
end
