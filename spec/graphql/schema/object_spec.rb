# frozen_string_literal: true
require "spec_helper"
describe GraphQL::Schema::Object do
  describe "class attributes" do
    let(:object_class) { Jazz::Ensemble }

    it "tells type data" do
      assert_equal "Ensemble", object_class.graphql_name
      assert_equal "A group of musicians playing together", object_class.description
      assert_equal 9, object_class.fields.size
      assert_equal [
          "GloballyIdentifiable",
          "HasMusicians",
          "InvisibleNameEntity",
          "NamedEntity",
          "PrivateNameEntity",
        ], object_class.interfaces.map(&:graphql_name).sort
      # It filters interfaces, too
      assert_equal [
          "GloballyIdentifiable",
          "HasMusicians",
          "InvisibleNameEntity",
          "NamedEntity"
        ], object_class.interfaces({}).map(&:graphql_name).sort
      # Compatibility methods are delegated to the underlying BaseType
      assert object_class.respond_to?(:connection_type)
    end

    describe "path" do
      it "is the type name" do
        assert_equal "Ensemble", object_class.path
      end
    end

    it "inherits fields and interfaces" do
      new_object_class = Class.new(object_class) do
        field :newField, String, null: true
        field :name, String, description: "The new description", null: true
      end

      # one more than the parent class
      assert_equal 10, new_object_class.fields.size
      # inherited interfaces are present
      assert_equal [
          "GloballyIdentifiable",
          "HasMusicians",
          "InvisibleNameEntity",
          "NamedEntity",
          "PrivateNameEntity",
        ], new_object_class.interfaces.map(&:graphql_name).sort
      # The new field is present
      assert new_object_class.fields.key?("newField")
      # The overridden field is present:
      name_field = new_object_class.fields["name"]
      assert_equal "The new description", name_field.description
    end

    it "inherits name and description" do
      # Manually assign a name since `.name` isn't populated for dynamic classes
      new_subclass_1 = Class.new(object_class) do
        graphql_name "NewSubclass"
      end
      new_subclass_2 = Class.new(new_subclass_1)
      assert_equal "NewSubclass", new_subclass_1.graphql_name
      assert_equal "NewSubclass", new_subclass_2.graphql_name
      assert_equal object_class.description, new_subclass_2.description
    end

    it "implements visibility constrained interface when context is private" do
      found_interfaces = object_class.interfaces({ private: true })
      assert_equal 5, found_interfaces.count
      assert found_interfaces.any? { |int| int.graphql_name == 'PrivateNameEntity' }
    end

    it "should take Ruby name (without Type suffix) as default graphql name" do
      TestingClassType = Class.new(GraphQL::Schema::Object)
      assert_equal "TestingClass", TestingClassType.graphql_name
    end

    it "raise on anonymous class without declared graphql name" do
      anonymous_class = Class.new(GraphQL::Schema::Object)
      assert_raises GraphQL::RequiredImplementationMissingError do
        anonymous_class.graphql_name
      end
    end

    class OverrideNameObject < GraphQL::Schema::Object
      class << self
        def default_graphql_name
          "Override"
        end
      end
    end

    it "can override the default graphql_name" do
      override_name_object = OverrideNameObject

      assert_equal "Override", override_name_object.graphql_name
    end
  end

  describe "implementing interfaces" do
    it "raises an error when trying to implement a non-interface module" do
      object_type = Class.new(GraphQL::Schema::Object)

      module NotAnInterface
      end

      err = assert_raises do
        object_type.implements(NotAnInterface)
      end

      message = "NotAnInterface cannot be implemented since it's not a GraphQL Interface. Use `include` for plain Ruby modules."
      assert_equal message, err.message
    end

    it "does not inherit singleton methods from base interface when implementing another interface" do
      object_type = Class.new(GraphQL::Schema::Object)
      methods = object_type.singleton_methods
      method_defs = Hash[methods.zip(methods.map{|method| object_type.method(method.to_sym)})]

      module InterfaceType
        include GraphQL::Schema::Interface
      end

      object_type.implements(InterfaceType)
      new_method_defs = Hash[methods.zip(methods.map{|method| object_type.method(method.to_sym)})]
      assert_equal method_defs, new_method_defs
    end

    it "can implement legacy interfaces" do
      object_type = Class.new(GraphQL::Schema::Object) do
        implements GraphQL::Relay::Node.interface # class-based would be `GraphQL::Types::Relay::Node`
      end
      assert_equal ["Node"], object_type.interfaces.map(&:graphql_name)
      assert_equal ["id"], object_type.fields.keys
    end
  end

  if !TESTING_INTERPRETER
  describe "using GraphQL::Function" do # rubocop:disable Layout/IndentationWidth
    new_test_func_payload = Class.new(GraphQL::Schema::Object) do
      graphql_name "TestFuncPayload"
      field :name, String, null: false
    end

    it "returns data on a field" do
      new_func_class = Class.new(GraphQL::Function) do
        argument :name, GraphQL::STRING_TYPE
        type new_test_func_payload

        def call(o, a, c)
          { name: a[:name] }
        end
      end

      new_object_class = Class.new(GraphQL::Schema::Object) do
        graphql_name "GraphQL"
        field :test, function: new_func_class.new
      end

      schema = Class.new(GraphQL::Schema) do
        query(new_object_class)
      end

      query_str = <<-GRAPHQL
      {
        test(name: "graphql") {
          name
        }
      }
      GRAPHQL
      res = schema.execute(query_str)
      assert_equal "graphql", res["data"]["test"]["name"]
    end

    it "returns data on a connection" do
      new_func_class = Class.new(GraphQL::Function) do
        argument :name, GraphQL::STRING_TYPE
        type new_test_func_payload.connection_type

        def call(o, a, c)
          [{ name: a[:name] }]
        end
      end

      new_object_class = Class.new(GraphQL::Schema::Object) do
        graphql_name "GraphQL"
        field :test_conn, function: new_func_class.new
      end

      schema = Class.new(GraphQL::Schema) do
        query(new_object_class)
      end

      query_str = <<-GRAPHQL
      {
        testConn(name: "graphql") {
          edges {
            node {
              name
            }
          }
        }
      }
      GRAPHQL
      res = schema.execute(query_str)
      assert_equal "graphql", res["data"]["testConn"]["edges"][0]["node"]["name"]
    end
  end
  end

  describe "wrapping a Hash" do
    it "automatically looks up symbol and string keys" do
      query_str = <<-GRAPHQL
      {
        hashyEnsemble {
          musicians { name }
          formedAt
        }
      }
      GRAPHQL
      res = Jazz::Schema.execute(query_str)
      ensemble = res["data"]["hashyEnsemble"]
      assert_equal ["Jerry Garcia"], ensemble["musicians"].map { |m| m["name"] }
      assert_equal "May 5, 1965", ensemble["formedAt"]
    end

    it "works with strings and symbols" do
      query_str = <<-GRAPHQL
      {
        hashByString { falsey }
        hashBySym { falsey }
      }
      GRAPHQL
      res = Jazz::Schema.execute(query_str)
      assert_equal false, res["data"]["hashByString"]["falsey"]
      assert_equal false, res["data"]["hashBySym"]["falsey"]
    end
  end

  describe "wrapping `nil`" do
    it "doesn't wrap nil in lists" do
      query_str = <<-GRAPHQL
      {
        namedEntities {
          name
        }
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      expected_items = [{"name" => "Bela Fleck and the Flecktones"}, nil]
      assert_equal expected_items, res["data"]["namedEntities"]
    end
  end

  describe ".to_graphql" do
    let(:obj_type) { Jazz::Ensemble.to_graphql }
    it "returns a matching GraphQL::ObjectType" do
      assert_equal "Ensemble", obj_type.name
      assert_equal "A group of musicians playing together", obj_type.description
      assert_equal 9, obj_type.all_fields.size

      name_field = obj_type.all_fields[3]
      assert_equal "name", name_field.name
      assert_equal GraphQL::STRING_TYPE.to_non_null_type, name_field.type
      assert_equal nil, name_field.description
    end

    it "has a custom implementation" do
      assert_equal obj_type.metadata[:config], :configged
    end

    it "uses the custom field class" do
      query_str = <<-GRAPHQL
      {
        ensembles { upcaseName }
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      assert_equal ["BELA FLECK AND THE FLECKTONES", "ROBERT GLASPER EXPERIMENT"], res["data"]["ensembles"].map { |e| e["upcaseName"] }
    end

    it "passes on type memberships from superclasses" do
      obj_type = Jazz::StylishMusician.to_graphql
      parent_obj_type = Jazz::Musician.to_graphql
      assert_equal parent_obj_type.interfaces, obj_type.interfaces
    end
  end


  describe "in queries" do
    after {
      Jazz::Models.reset
    }

    it "returns data" do
      query_str = <<-GRAPHQL
      {
        ensembles { name }
        instruments { name }
      }
      GRAPHQL
      res = Jazz::Schema.execute(query_str)
      expected_ensembles = [
        {"name" => "Bela Fleck and the Flecktones"},
        {"name" => "ROBERT GLASPER Experiment"},
      ]
      assert_equal expected_ensembles, res["data"]["ensembles"]
      assert_equal({"name" => "Banjo"}, res["data"]["instruments"].first)
    end

    it "does mutations" do
      mutation_str = <<-GRAPHQL
      mutation AddEnsemble($name: String!) {
        addEnsemble(input: { name: $name }) {
          id
        }
      }
      GRAPHQL

      query_str = <<-GRAPHQL
      query($id: ID!) {
        find(id: $id) {
          ... on Ensemble {
            name
          }
        }
      }
      GRAPHQL

      res = Jazz::Schema.execute(mutation_str, variables: { name: "Miles Davis Quartet" })
      new_id = res["data"]["addEnsemble"]["id"]

      res2 = Jazz::Schema.execute(query_str, variables: { id: new_id })
      assert_equal "Miles Davis Quartet", res2["data"]["find"]["name"]
    end

    it "initializes root wrappers once" do
      query_str = " { oid1: objectId oid2: objectId }"
      res = Jazz::Schema.execute(query_str)
      assert_equal res["data"]["oid1"], res["data"]["oid2"]
    end

    it "skips fields properly" do
      query_str = "{ find(id: \"MagicalSkipId\") { __typename } }"
      res = Jazz::Schema.execute(query_str)
      # TBH I think `{}` is probably righter than `nil`, I guess we'll see.
      skip_value = TESTING_INTERPRETER ? {} : nil
      assert_equal({"data" => skip_value }, res.to_h)
    end
  end

  describe "when fields conflict with built-ins" do
    it "warns when no override" do
      expected_warning = "X's `field :method` conflicts with a built-in method, use `resolver_method:` to pick a different resolver method for this field (for example, `resolver_method: :resolve_method` and `def resolve_method`). Or use `method_conflict_warning: false` to suppress this warning.\n"
      assert_output "", expected_warning do
        Class.new(GraphQL::Schema::Object) do
          graphql_name "X"
          field :method, String, null: true
        end
      end
    end

    it "warns when override matches field name" do
      expected_warning = "X's `field :object` conflicts with a built-in method, use `resolver_method:` to pick a different resolver method for this field (for example, `resolver_method: :resolve_object` and `def resolve_object`). Or use `method_conflict_warning: false` to suppress this warning.\n"
      assert_output "", expected_warning do
        Class.new(GraphQL::Schema::Object) do
          graphql_name "X"
          field :object, String, null: true, resolver_method: :object
        end
      end
    end

    it "doesn't warn with a resolver_method: override" do
      assert_output "", "" do
        Class.new(GraphQL::Schema::Object) do
          graphql_name "X"
          field :method, String, null: true, resolver_method: :resolve_method
        end
      end
    end

    it "doesn't warn with a method: override" do
      assert_output "", "" do
        Class.new(GraphQL::Schema::Object) do
          graphql_name "X"
          field :module, String, null: true, method: :mod
        end
      end
    end

    it "doesn't warn with a suppression" do
      assert_output "", "" do
        Class.new(GraphQL::Schema::Object) do
          graphql_name "X"
          field :method, String, null: true, method_conflict_warning: false
        end
      end
    end

    it "doesn't warn when parsing a schema" do
      assert_output "", "" do
        schema = GraphQL::Schema.from_definition <<-GRAPHQL
        type Query {
          method: String
        }
        GRAPHQL
        assert_equal ["method"], schema.query.fields.keys
      end
    end

    it "doesn't warn when passing object through using resolver_method" do
      assert_output "", "" do
        Class.new(GraphQL::Schema::Object) do
          graphql_name "X"
          field :thing, String, null: true, resolver_method: :object
        end
      end
    end
  end

  describe "type-specific invalid null errors" do
    class ObjectInvalidNullSchema < GraphQL::Schema
      module Numberable
        include GraphQL::Schema::Interface

        field :float, Float, null: false

        def float
          nil
        end
      end

      class Query < GraphQL::Schema::Object
        implements Numberable

        field :int, Integer, null: false
        def int
          nil
        end
      end
      query(Query)

      def self.type_error(err, ctx)
        raise err
      end

      use GraphQL::Execution::Interpreter
      use GraphQL::Analysis::AST
    end

    it "raises them when invalid nil is returned" do
      assert_raises(ObjectInvalidNullSchema::Query::InvalidNullError) do
        ObjectInvalidNullSchema.execute("{ int }")
      end
    end

    it "raises them for fields inherited from interfaces" do
      assert_raises(ObjectInvalidNullSchema::Query::InvalidNullError) do
        ObjectInvalidNullSchema.execute("{ float }")
      end
    end
  end
end
