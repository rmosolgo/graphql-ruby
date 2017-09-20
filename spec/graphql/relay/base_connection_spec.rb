# frozen_string_literal: true
require 'spec_helper'

describe GraphQL::Relay::BaseConnection do
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
      conn = GraphQL::Relay::BaseConnection.new([], args)
      assert_equal 1, conn.first
      assert_equal 0, conn.last

      args = {
        first: nil,
      }
      conn = GraphQL::Relay::BaseConnection.new([], args)
      assert_equal nil, conn.first
    end
  end

  describe "#encode / #decode" do
    module ReverseCoder
      module_function
      def encode(str, nonce: false); str.reverse; end
      def decode(str, nonce: false); str.reverse; end
    end

    it "Uses the schema's coder" do
      conn = GraphQL::Relay::BaseConnection.new([], {}, coder: ReverseCoder)

      assert_equal "1/nosreP", conn.encode("Person/1")
      assert_equal "Person/1", conn.decode("1/nosreP")
    end

    it "defaults to base64" do
      conn = GraphQL::Relay::BaseConnection.new([], {})

      assert_equal "UGVyc29uLzE=", conn.encode("Person/1")
      assert_equal "Person/1", conn.decode("UGVyc29uLzE=")
    end

    it "handles trimmed base64" do
      conn = GraphQL::Relay::BaseConnection.new([], {})

      assert_equal "Person/1", conn.decode("UGVyc29uLzE")
    end
  end
end
