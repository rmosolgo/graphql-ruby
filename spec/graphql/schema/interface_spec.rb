# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Interface do
  let(:interface) { Jazz::GloballyIdentifiable }

  describe "type info" do
    it "tells its type info" do
      assert_equal "GloballyIdentifiable", interface.graphql_name
      assert_equal 2, interface.fields.size
    end

    it "inherits implemented hook" do
      block_was_called = false
      new_interface = Class.new(interface) do
        implemented do
          block_was_called = true
        end
      end

      new_object = Class.new(GraphQL::Schema::Object) do
        implements new_interface
      end

      assert_equal 2, new_object.fields.size
      assert new_object.method_defined?(:id)
      assert block_was_called
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
          upcasedId
          ... on Instrument {
            family
          }
        }
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      expected_piano = {
        "id" => "Instrument/Piano",
        "upcasedId" => "INSTRUMENT/PIANO",
        "family" => "KEYS",
      }
      assert_equal(expected_piano, res["data"]["piano"])
    end

    it "applies custom field attributes" do
      query_str = <<-GRAPHQL
      {
        find(id: "Ensemble/Bela Fleck and the Flecktones") {
          upcasedId
          ... on Ensemble {
            name
          }
        }
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      expected_data = {
        "upcasedId" => "ENSEMBLE/BELA FLECK AND THE FLECKTONES",
        "name" => "Bela Fleck and the Flecktones"
      }
      assert_equal(expected_data, res["data"]["find"])
    end
  end
end
