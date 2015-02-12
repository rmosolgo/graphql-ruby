require 'spec_helper'
require 'ostruct'

describe GraphQL::Field do
  let(:owner) { OpenStruct.new(name: "TestOwner")}
  let(:field) { GraphQL::Field.create_class(name: "high_fives", type: :number, owner_class: owner).new(query: {}) }

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
      handslap_field = GraphQL::Field.create_class(name: "high_fives", method: "handslaps",  type: :number, owner_class: owner).new(query: {})
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

  describe '__type__' do
    let(:query_string) { "type(Post) { fields { edges { node { name, type, calls { edges { node { name } }} } } } } "}
    let(:query) { GraphQL::Query.new(query_string, namespace: Nodes, context: {}) }
    let(:result) { query.as_json }

    it 'has name' do
      assert_equal "title",     result["Post"]["fields"]["edges"][0]["node"]["name"]
      assert_equal "content",   result["Post"]["fields"]["edges"][1]["node"]["name"]
      assert_equal "length",    result["Post"]["fields"]["edges"][2]["node"]["name"]
      assert_equal "comments",  result["Post"]["fields"]["edges"][3]["node"]["name"]
    end

    it 'has type' do
      assert_equal "string",      result["Post"]["fields"]["edges"][0]["node"]["type"]
      assert_equal "string",      result["Post"]["fields"]["edges"][1]["node"]["type"]
      assert_equal "number",      result["Post"]["fields"]["edges"][2]["node"]["type"]
      assert_equal "connection",  result["Post"]["fields"]["edges"][3]["node"]["type"]
    end

    it 'has calls' do
      content_calls = result["Post"]["fields"]["edges"][1]["node"]["calls"]["edges"]
      assert_equal 3, content_calls.length
      assert_equal ["from", "for", "select"], content_calls.map {|c| c["node"]["name"] }
    end
  end
end