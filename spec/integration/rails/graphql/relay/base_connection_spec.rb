# frozen_string_literal: true
require 'spec_helper'

describe GraphQL::Relay::BaseConnection do
  module Encoder
    module_function
    def encode(str, nonce: false); str; end
    def decode(str, nonce: false); str; end
  end

  let(:schema) { OpenStruct.new(cursor_encoder: Encoder) }
  let(:context) { OpenStruct.new(schema: schema) }

  describe ".connection_for_nodes" do
    it "resolves most specific connection type" do
      class SpecialArray < Array; end
      class SpecialArrayConnection < GraphQL::Relay::BaseConnection; end
      GraphQL::Relay::BaseConnection.register_connection_implementation(SpecialArray, SpecialArrayConnection)

      nodes = SpecialArray.new

      conn_class = GraphQL::Relay::BaseConnection.connection_for_nodes(nodes)
      assert_equal conn_class, SpecialArrayConnection
    end
  end

  describe "arguments" do
    it "limits pagination args to positive numbers" do
      args = {
        first: 1,
        last: -1,
      }
      conn = GraphQL::Relay::BaseConnection.new([], args, context: context)
      assert_equal 1, conn.first
      assert_equal 0, conn.last

      args = {
        first: nil,
      }
      conn = GraphQL::Relay::BaseConnection.new([], args, context: context)
      assert_nil conn.first
    end
  end

  describe "#context" do
    it "Has public access to the field context" do
      conn = GraphQL::Relay::BaseConnection.new([], {}, context: context)
      assert_equal context, conn.context
    end
  end

  describe "#inspect" do
    it "inspects nicely" do
      args = {
        first: 1,
        last: -1,
      }
      conn = GraphQL::Relay::BaseConnection.new([], args, context: context)
      assert_equal "#<GraphQL::Relay::Connection @parent=nil @arguments={:first=>1, :last=>-1}>", conn.inspect
    end
  end

  describe "#encode / #decode" do
    module ReverseEncoder
      module_function
      def encode(str, nonce: false); str.reverse; end
      def decode(str, nonce: false); str.reverse; end
    end

    let(:schema) { OpenStruct.new(cursor_encoder: ReverseEncoder) }
    let(:context) { OpenStruct.new(schema: schema) }

    it "Uses the schema's encoder" do
      conn = GraphQL::Relay::BaseConnection.new([], {}, context: context)

      assert_equal "1/nosreP", conn.encode("Person/1")
      assert_equal "Person/1", conn.decode("1/nosreP")
    end

    it "defaults to base64" do
      conn = GraphQL::Relay::BaseConnection.new([], {}, context: nil)

      assert_equal "UGVyc29uLzE=", conn.encode("Person/1")
      assert_equal "Person/1", conn.decode("UGVyc29uLzE=")
    end

    it "handles trimmed base64" do
      conn = GraphQL::Relay::BaseConnection.new([], {}, context: nil)

      assert_equal "Person/1", conn.decode("UGVyc29uLzE")
    end
  end
end
