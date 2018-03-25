# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Interface do
  let(:interface) { Jazz::GloballyIdentifiableType }

  describe "type info" do
    it "tells its type info" do
      assert_equal "GloballyIdentifiable", interface.graphql_name
      assert_equal 2, interface.fields.size
    end

    class NewInterface1 < Jazz::GloballyIdentifiableType
    end

    class NewInterface2 < Jazz::GloballyIdentifiableType
      module Implementation
        def new_method
        end
      end
    end

    it "can override Implementation" do
      new_object_1 = Class.new(GraphQL::Schema::Object) do
        implements NewInterface1
      end

      assert_equal 2, new_object_1.fields.size
      assert new_object_1.method_defined?(:id)

      new_object_2 = Class.new(GraphQL::Schema::Object) do
        implements NewInterface2
      end

      assert_equal 2, new_object_2.fields.size
      # It got the new method
      assert new_object_2.method_defined?(:new_method)
      # But not the old method
      refute new_object_2.method_defined?(:id)
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
      assert_nil interface_type.resolve_type_proc
      assert_empty interface_type.orphan_types
    end

    it "can specify a resolve_type method" do
      interface = Class.new(GraphQL::Schema::Interface) do
        def self.resolve_type(_object, _context)
          "MyType"
        end

        def self.name
          "MyInterface"
        end
      end
      interface_type = interface.to_graphql
      assert_equal "MyType", interface_type.resolve_type_proc.call(nil, nil)
    end

    it "can specify orphan types" do
      interface = Class.new(GraphQL::Schema::Interface) do
        def self.name
          "MyInterface"
        end

        orphan_types Dummy::CheeseType, Dummy::HoneyType
      end

      interface_type = interface.to_graphql
      assert_equal [Dummy::CheeseType, Dummy::HoneyType], interface_type.orphan_types
    end
  end

  it 'supports global_id_field' do
    object = Class.new(GraphQL::Schema::Interface) do
      graphql_name 'GlobalIdFieldTest'
      global_id_field :uuid
    end.to_graphql
    uuid_field = object.fields["uuid"]

    assert_equal GraphQL::NonNullType, uuid_field.type.class
    assert_equal GraphQL::ScalarType, uuid_field.type.unwrap.class
    assert_equal(
      GraphQL::Schema::Member::GraphQLTypeNames::ID,
      uuid_field.type.unwrap.name
    )
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
