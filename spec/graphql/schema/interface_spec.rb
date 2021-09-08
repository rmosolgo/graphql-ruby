# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Interface do
  let(:interface) { Jazz::GloballyIdentifiableType }

  describe ".path" do
    it "is the name" do
      assert_equal "GloballyIdentifiable", interface.path
    end
  end

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
      assert_equal GraphQL::DEPRECATED_ID_TYPE.to_non_null_type, field.type
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
        orphan_types Dummy::Cheese, Dummy::Honey
      end

      interface_type = interface.to_graphql
      assert_equal [Dummy::Cheese, Dummy::Honey], interface_type.orphan_types
    end
  end

  it 'supports global_id_field' do
    object = Module.new do
      include GraphQL::Schema::Interface
      graphql_name 'GlobalIdFieldTest'
      global_id_field :uuid, description: 'The UUID field'
    end.to_graphql

    uuid_field = object.fields["uuid"]

    assert_equal GraphQL::NonNullType, uuid_field.type.class
    assert_equal GraphQL::ScalarType, uuid_field.type.unwrap.class
    assert_equal 'The UUID field', uuid_field.description
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

    module InterfaceD
      include InterfaceA

      definition_methods do
        def some_method
          'not 42'
        end
      end
    end

    module InterfaceE
      include InterfaceD
    end

    it "doesn't overwrite them when including multiple interfaces" do
      def_methods = InterfaceC::DefinitionMethods

      InterfaceC.module_eval do
        include InterfaceA
        include InterfaceB
      end

      assert_equal(InterfaceC::DefinitionMethods, def_methods)
    end

    it "follows the normal Ruby ancestor chain when including other interfaces" do
      assert_equal('not 42', InterfaceE.some_method)
    end
  end

  describe "can implement other interfaces" do
    class InterfaceImplementsSchema < GraphQL::Schema
      module InterfaceA
        include GraphQL::Schema::Interface
        field :a, String, null: true

        def a; "a"; end
      end

      module InterfaceB
        include GraphQL::Schema::Interface
        implements InterfaceA
        field :b, String, null: true

        def b; "b"; end
      end

      class Query < GraphQL::Schema::Object
        implements InterfaceB
      end

      query(Query)
    end

    it "runs queries on inherited interfaces" do
      result = InterfaceImplementsSchema.execute("{ a b }")
      assert_equal "a", result["data"]["a"]
      assert_equal "b", result["data"]["b"]

      result2 = InterfaceImplementsSchema.execute(<<-GRAPHQL)
      {
        ... on InterfaceA {
          ... on InterfaceB {
            f1: a
            f2: b
          }
        }
      }
      GRAPHQL
      assert_equal "a", result2["data"]["f1"]
      assert_equal "b", result2["data"]["f2"]
    end

    it "shows up in introspection" do
      result = InterfaceImplementsSchema.execute("{ __type(name: \"InterfaceB\") { interfaces { name } } }")
      assert_equal ["InterfaceA"], result["data"]["__type"]["interfaces"].map { |i| i["name"] }
    end

    it "has the right structure" do
      expected_schema = <<-SCHEMA
interface InterfaceA {
  a: String
}

interface InterfaceB implements InterfaceA {
  a: String
  b: String
}

type Query implements InterfaceA & InterfaceB {
  a: String
  b: String
}
      SCHEMA
      assert_equal expected_schema, InterfaceImplementsSchema.to_definition
    end
  end

  describe "migrated legacy tests" do
    let(:interface) { Dummy::Edible }

    it "has possible types" do
      expected_defns = [Dummy::Cheese, Dummy::Milk, Dummy::Honey, Dummy::Aspartame]
      assert_equal(expected_defns, Dummy::Schema.possible_types(interface))
    end

    describe "query evaluation" do
      let(:result) { Dummy::Schema.execute(query_string, variables: {"cheeseId" => 2})}
      let(:query_string) {%|
        query fav {
          favoriteEdible { fatContent }
        }
      |}
      it "gets fields from the type for the given object" do
        expected = {"data"=>{"favoriteEdible"=>{"fatContent"=>0.04}}}
        assert_equal(expected, result)
      end
    end

    describe "mergable query evaluation" do
      let(:result) { Dummy::Schema.execute(query_string, variables: {"cheeseId" => 2})}
      let(:query_string) {%|
        query fav {
          favoriteEdible { fatContent }
          favoriteEdible { origin }
        }
      |}
      it "gets fields from the type for the given object" do
        expected = {"data"=>{"favoriteEdible"=>{"fatContent"=>0.04, "origin"=>"Antiquity"}}}
        assert_equal(expected, result)
      end
    end

    describe "fragments" do
      let(:query_string) {%|
      {
        favoriteEdible {
          fatContent
          ... on LocalProduct {
            origin
          }
        }
      }
      |}
      let(:result) { Dummy::Schema.execute(query_string) }

      it "can apply interface fragments to an interface" do
        expected_result = { "data" => {
          "favoriteEdible" => {
            "fatContent" => 0.04,
            "origin" => "Antiquity",
          }
        } }

        assert_equal(expected_result, result)
      end

      describe "filtering members by type" do
        let(:query_string) {%|
        {
          allEdible {
            __typename
            ... on LocalProduct {
              origin
            }
          }
        }
        |}

        it "only applies fields to the right object" do
          expected_data = [
            {"__typename"=>"Cheese", "origin"=>"France"},
            {"__typename"=>"Cheese", "origin"=>"Netherlands"},
            {"__typename"=>"Cheese", "origin"=>"Spain"},
            {"__typename"=>"Milk", "origin"=>"Antiquity"},
          ]

          assert_equal expected_data, result["data"]["allEdible"]
        end
      end
    end


    describe "#resolve_type" do
      let(:result) { Dummy::Schema.execute(query_string) }
      let(:query_string) {%|
        {
          allEdible {
            __typename
            ... on Milk {
              milkFatContent: fatContent
            }
            ... on Cheese {
              cheeseFatContent: fatContent
            }
          }

          allEdibleAsMilk {
            __typename
            ... on Milk {
              fatContent
            }
          }
        }
      |}

      it 'returns correct types for general schema and specific interface' do
        expected_result = {
          # Uses schema-level resolve_type
          "allEdible"=>[
            {"__typename"=>"Cheese", "cheeseFatContent"=>0.19},
            {"__typename"=>"Cheese", "cheeseFatContent"=>0.3},
            {"__typename"=>"Cheese", "cheeseFatContent"=>0.065},
            {"__typename"=>"Milk", "milkFatContent"=>0.04}
          ],
          # Uses type-level resolve_type
          "allEdibleAsMilk"=>[
            {"__typename"=>"Milk", "fatContent"=>0.19},
            {"__typename"=>"Milk", "fatContent"=>0.3},
            {"__typename"=>"Milk", "fatContent"=>0.065},
            {"__typename"=>"Milk", "fatContent"=>0.04}
          ]
        }
        assert_equal expected_result, result["data"]
      end
    end
  end
end
