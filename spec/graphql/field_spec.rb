require 'spec_helper'
require 'ostruct'

describe GraphQL::Field do
  let(:owner) { OpenStruct.new(name: "TestOwner")}
  let(:field) { GraphQL::Field.create_class(name: "high_fives", owner: owner).new(query: {}) }
  describe '#name' do
    it 'is present' do
      assert_equal field.name, "high_fives"
    end
  end

  describe '#method' do
    it 'defaults to name' do
      assert_equal "high_fives", field.method
    end

    it 'can be overriden' do
      handslap_field = GraphQL::Field.create_class(name: "high_fives", method: "handslaps", owner: owner).new(query: {})
      assert_equal "high_fives", handslap_field.name
      assert_equal "handslaps", handslap_field.method
    end
  end

  describe '.to_s' do
    it 'includes name' do
      assert_match(/high_fives/, field.class.to_s)
    end
    it 'includes owner name' do
      assert_match(/TestOwner/, field.class.to_s)
    end
  end
end