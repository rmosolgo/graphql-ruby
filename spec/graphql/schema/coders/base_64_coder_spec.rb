# frozen_string_literal: true
require 'spec_helper'

describe GraphQL::Schema::Coders::Base64Coder do
  it 'base64 encodes a string' do
    result = GraphQL::Schema::Coders::Base64Coder.encode('test')
    assert_equal("dGVzdA==", result)
  end

  it 'decodes a base64 string' do
    result = GraphQL::Schema::Coders::Base64Coder.decode('dGVzdA==')
    assert_equal('test', result)
  end

  it 'works with a roundtrip encode/decode' do
    original_string = 'test'
    assert_equal(
      original_string,
      GraphQL::Schema::Coders::Base64Coder.decode(
        GraphQL::Schema::Coders::Base64Coder.encode(original_string)
      )
    )
  end
end
