require 'spec_helper'

describe GraphQL::ScalarType do
  let(:debug) { false }
  let(:query) { GraphQL::Query.new(DummySchema, query_string, debug: debug)}
  let(:result) { query.result }

  describe 'ID coercion for int inputs' do
    let(:query_string) { %|query getMilk { cow: milk(id: 1) { id } }| }

    it 'coerces IDs from ints and serializes as strings' do
      expected = {"data" => {"getMilk" => {"cow" => {"id" => "1"}}}}
      assert_equal(expected, result)
    end
  end

  describe 'ID coercion for string inputs' do
    let(:query_string) { %|query getMilk { cow: milk(id: "1") { id } }| }

    it 'coerces IDs from strings and serializes as strings' do
      expected = {"data" => {"getMilk" => {"cow" => {"id" => "1"}}}}
      assert_equal(expected, result)
    end
  end
end

