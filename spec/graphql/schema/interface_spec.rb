# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Interface do
  let(:interface) { Jazz::GloballyIdentifiableType }

  describe "type info" do
    it "tells its type info" do
      assert_equal "GloballyIdentifiable", interface.graphql_name
      assert_equal 2, interface.fields.size
    end

    module NewInterface1
      include Jazz::GloballyIdentifiableType
    end

    module NewInterface2
      include Jazz::GloballyIdentifiableType
      def new_method
      end
    end

    it "can override methods" do
      new_object_1 = Class.new(GraphQL::Schema::Object) do
        implements NewInterface1
      end

      assert_equal 2, new_object_1.fields.size
      assert new_object_1.method_defined?(:id)

      new_object_2 = Class.new(GraphQL::Schema::Object) do
        graphql_name "XYZ"
        implements NewInterface2
        field :id, "ID", null: false, description: "The ID !!!!!"
      end

      assert_equal 2, new_object_2.fields.size
      # It got the new method
      assert new_object_2.method_defined?(:new_method)
      # And the inherited method
      assert new_object_2.method_defined?(:id)

      # It gets an overridden description:
      assert_equal "The ID !!!!!", new_object_2.graphql_definition.fields["id"].description
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
      interface = Module.new do
        include GraphQL::Schema::Interface
        graphql_name "MyInterface"

        module self::DefinitionMethods # rubocop:disable Style/ClassAndModuleChildren
          def resolve_type(_object, _context)
            "MyType"
          end
        end
      end

      interface_type = interface.to_graphql
      assert_equal "MyType", interface_type.resolve_type_proc.call(nil, nil)
    end

    it "can specify orphan types" do
      interface = Module.new do
        include GraphQL::Schema::Interface
        graphql_name "MyInterface"
        orphan_types Dummy::CheeseType, Dummy::HoneyType
      end

      interface_type = interface.to_graphql
      assert_equal [Dummy::CheeseType, Dummy::HoneyType], interface_type.orphan_types
    end
  end

  it 'supports global_id_field' do
    object = Module.new do
      include GraphQL::Schema::Interface
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

  describe "using `include`" do
    it "raises" do
      err = assert_raises RuntimeError do
        Class.new(GraphQL::Schema::Object) do
          include(Jazz::GloballyIdentifiableType)
        end
      end

      assert_includes err.message, "implements(Jazz::GloballyIdentifiableType)"
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

  describe ':DefinitionMethods' do
    module InterfaceA
      include GraphQL::Schema::Interface

      definition_methods do
        def some_method
          42
        end
      end
    end

    module InterfaceB
      include GraphQL::Schema::Interface
    end

    module InterfaceC
      include GraphQL::Schema::Interface
    end

    class ObjectA < GraphQL::Schema::Object
      implements InterfaceA
    end

    it "doesn't overwrite them when including multiple interfaces" do
      def_methods = InterfaceC::DefinitionMethods

      InterfaceC.module_eval do
        include InterfaceA
        include InterfaceB
      end

      assert_equal(InterfaceC::DefinitionMethods, def_methods)
    end

    it "extends classes with the defined methods" do
      assert_equal(ObjectA.some_method, InterfaceA.some_method)
    end
  end
end
