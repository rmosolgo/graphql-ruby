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
    let(:query_string) { "type(post) { fields { edges { node { name, type, calls { edges { node { name } }} } } } } "}
    let(:query) { GraphQL::Query.new(query_string, namespace: Nodes, context: {}) }
    let(:result) { query.as_json }
    let(:id_field)        { result["post"]["fields"]["edges"][0]["node"] }
    let(:title_field)     { result["post"]["fields"]["edges"][1]["node"] }
    let(:comments_field)  { result["post"]["fields"]["edges"][4]["node"] }
    let(:content_field)   { result["post"]["fields"]["edges"][2]["node"] }

    it 'has name' do
      assert_equal "id", id_field["name"]
      assert_equal "title", title_field["name"]
      assert_equal "comments", comments_field["name"]
    end

    it 'has type' do
      assert_equal "number", id_field["type"]
      assert_equal "string", title_field["type"]
      assert_equal "connection", comments_field["type"]
    end

    it 'has calls' do
      assert_equal 3, content_field["calls"]["edges"].length
      assert_equal ["from", "for", "select"], content_field["calls"]["edges"].map {|c| c["node"]["name"] }
    end
  end
end