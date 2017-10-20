# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Interface do
  let(:interface) { Jazz::GloballyIdentifiable::Interface }

  describe "type info" do
    it "tells its type info" do
      assert_equal "GloballyIdentifiable", interface.graphql_name
      assert_equal 1, interface.fields.size
    end
  end

  describe ".to_graphql" do
    it "creates an InterfaceType" do
      interface_type = interface.to_graphql
      assert_equal "GloballyIdentifiable", interface_type.name
      field = interface_type.all_fields.first
      assert_equal "id", field.name
      assert_equal GraphQL::ID_TYPE.to_non_null_type, field.type
      assert_equal "A unique identifier for this object", field.description
    end
  end

  describe "in queries" do
    it "works" do
      query_str = <<-GRAPHQL
      {
        piano: find(id: "Instrument/Piano") {
          id
          ... on Instrument {
            family
          }
        }
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      assert_equal({"id" => "Instrument/Piano", "family" => "KEYS"}, res["data"]["piano"])
    end
  end
end
