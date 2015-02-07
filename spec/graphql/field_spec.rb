require 'spec_helper'

describe GraphQL::Field do
  let(:field) { GraphQL::Field.new(name: "high_fives") }
  describe '#name' do
    it 'is present' do
      assert_equal field.name, "high_fives"
    end
  end

  describe '#method' do
    it 'defaults to name' do
      assert_equal field.method, "high_fives"
    end

    it 'can be overriden' do
      handslap_field = GraphQL::Field.new(name: "high_fives", method: "handslaps")
      assert_equal "high_fives", handslap_field.name
      assert_equal "handslaps", handslap_field.method
    end
  end
end