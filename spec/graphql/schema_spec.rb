# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema do
  let(:schema) { Dummy::Schema }
  let(:relay_schema)  { StarWars::Schema }
  let(:empty_schema) { GraphQL::Schema.define }

  describe "#graphql_definition" do
    it "returns itself" do
      assert_equal empty_schema, empty_schema.graphql_definition
    end
  end

  describe "#rescue_from" do
    it "adds handlers to the rescue middleware" do
      schema_defn = schema.graphql_definition
      rescue_middleware = schema_defn.middleware.first
      assert_equal(1, rescue_middleware.rescue_table.length)
      # normally, you'd use a real class, not a symbol:
      schema_defn.rescue_from(:error_class) { "my custom message" }
      assert_equal(2, rescue_middleware.rescue_table.length)
    end
  end

  describe "#find" do
    it "finds a member using a string path" do
      field = schema.find("Edible.fatContent")
      assert_equal "fatContent", field.name
    end
  end

  describe "#union_memberships" do
    it "returns a list of unions that include the type" do
      assert_equal [schema.types["Animal"], schema.types["AnimalAsCow"]], schema.union_memberships(schema.types["Cow"])
    end
  end

  describe "#to_document" do
    it "returns the AST for the schema IDL" do
      expected = GraphQL::Language::DocumentFromSchemaDefinition.new(schema).document
      assert expected.eql?(schema.to_document)
    end
  end

  describe "#root_types" do
    it "returns a list of the schema's root types" do
      assert_equal(
        [
          Dummy::DairyAppQueryType,
          Dummy::DairyAppMutationType.graphql_definition,
          Dummy::SubscriptionType
        ],
        schema.root_types
      )
    end
  end

  describe "#references_to" do
    it "returns a list of Field and Arguments of that type" do
      assert_equal [schema.types["Query"].fields["cow"]], schema.references_to("Cow")
    end

    it "returns an empty list when type is not referenced by any field or argument" do
      assert_equal [], schema.references_to("Goat")
    end
  end

  describe "#to_definition" do
    it "prints out the schema definition" do
      assert_equal schema.to_definition, GraphQL::Schema::Printer.print_schema(schema)
    end
  end

  describe "#subscription" do
    it "calls fields on the subscription type" do
      res = schema.execute("subscription { test }")
      assert_equal("Test", res["data"]["test"])
    end
  end

  describe "#resolve_type" do
    describe "when the return value is nil" do
      it "returns nil" do
        result = relay_schema.resolve_type(123, nil)
        assert_equal(nil, result)
      end
    end

    describe "when the return value is not a BaseType" do
      it "raises an error " do
        err = assert_raises(RuntimeError) {
          relay_schema.resolve_type(:test_error, nil)
        }
        assert_includes err.message, "not_a_type (Symbol)"
      end
    end

    describe "when the hook wasn't implemented" do
      it "raises not implemented" do
        assert_raises(NotImplementedError) {
          empty_schema.resolve_type(nil, nil)
        }
      end
    end

    describe "when a schema is defined with abstract types, but no resolve type hook" do
      it "raises not implemented" do
        interface = GraphQL::InterfaceType.define do
          name "SomeInterface"
        end

        query_type = GraphQL::ObjectType.define do
          name "Query"
          field :something, interface
        end

        assert_raises(NotImplementedError) {
          GraphQL::Schema.define do
            query(query_type)
          end
        }
      end
    end
  end

  describe "object_from_id" do
    describe "when the hook wasn't implemented" do
      it "raises not implemented" do
        assert_raises(NotImplementedError) {
          empty_schema.object_from_id(nil, nil)
        }
      end
    end

    describe "when a schema is defined with a relay ID field, but no hook" do
      it "raises not implemented" do
        thing_type = GraphQL::ObjectType.define do
          name "Thing"
          global_id_field :id
        end

        query_type = GraphQL::ObjectType.define do
          name "Query"
          field :thing, thing_type
        end

        assert_raises(NotImplementedError) {
          GraphQL::Schema.define do
            query(query_type)
            resolve_type NO_OP_RESOLVE_TYPE
          end
        }
      end
    end
  end

  describe "id_from_object" do
    describe "when the hook wasn't implemented" do
      it "raises not implemented" do
        assert_raises(NotImplementedError) {
          empty_schema.id_from_object(nil, nil, nil)
        }
      end
    end

    describe "when a schema is defined with a node field, but no hook" do
      it "raises not implemented" do
        query_type = GraphQL::ObjectType.define do
          name "Query"
          field :node, GraphQL::Relay::Node.field
        end

        assert_raises(NotImplementedError) {
          GraphQL::Schema.define do
            query(query_type)
            resolve_type NO_OP_RESOLVE_TYPE
          end
        }
      end
    end
  end

  describe "directives" do
    describe "when directives are not overwritten" do
      it "contains built-in directives" do
        schema = GraphQL::Schema.define

        assert_equal ['deprecated', 'include', 'skip'], schema.directives.keys.sort

        assert_equal GraphQL::Directive::DeprecatedDirective, schema.directives['deprecated']
        assert_equal GraphQL::Directive::IncludeDirective, schema.directives['include']
        assert_equal GraphQL::Directive::SkipDirective, schema.directives['skip']
      end
    end

    describe "when directives are overwritten" do
      it "contains only specified directives" do
        schema = GraphQL::Schema.define do
          directives [GraphQL::Directive::DeprecatedDirective]
        end

        assert_equal ['deprecated'], schema.directives.keys.sort
        assert_equal GraphQL::Directive::DeprecatedDirective, schema.directives['deprecated']
      end
    end
  end

  describe ".from_definition" do
    it "uses BuildFromSchema to build a schema from a definition string" do
      schema = <<-SCHEMA
type Query {
  str: String
}
      SCHEMA

      built_schema = GraphQL::Schema.from_definition(schema)
      assert_equal schema.chop, GraphQL::Schema::Printer.print_schema(built_schema)
    end

    it "builds from a file" do
      schema = GraphQL::Schema.from_definition("spec/support/magic_cards/schema.graphql")
      assert_instance_of GraphQL::Schema, schema
      expected_types =  ["Card", "Color", "Expansion", "Printing"]
      assert_equal expected_types, (expected_types & schema.types.keys)
    end
  end

  describe ".from_introspection" do
    let(:schema) {
      query_root = GraphQL::ObjectType.define do
        name 'Query'
        field :str, types.String
      end

      GraphQL::Schema.define do
        query query_root
      end
    }
    let(:schema_json) {
      schema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)
    }
    it "uses Schema::Loader to build a schema from an introspection result" do
      built_schema = GraphQL::Schema.from_introspection(schema_json)
      assert_equal GraphQL::Schema::Printer.print_schema(schema), GraphQL::Schema::Printer.print_schema(built_schema)
    end
  end

  describe "#instrument" do
    class MultiplyInstrumenter
      def initialize(multiplier)
        @multiplier = multiplier
      end

      def instrument(type_defn, field_defn)
        if type_defn.name == "Query" && field_defn.name == "int"
          prev_proc = field_defn.resolve_proc
          new_resolve_proc = ->(obj, args, ctx) {
            inner_value = prev_proc.call(obj, args, ctx)
            inner_value * @multiplier
          }

          field_defn.redefine do
            resolve(new_resolve_proc)
          end
        else
          field_defn
        end
      end
    end

    class VariableCountInstrumenter
      attr_reader :counts
      def initialize
        @counts = []
      end

      def before_query(query)
        @counts << query.variables.length
      end

      def after_query(query)
        @counts << :end
      end
    end

    # Use this to assert instrumenters are called as a stack
    class StackCheckInstrumenter
      def initialize(counter)
        @counter = counter
      end

      def before_query(query)
        @counter.counts << :in
      end

      def after_query(query)
        @counter.counts << :out
      end
    end

    let(:variable_counter) {
      VariableCountInstrumenter.new
    }
    let(:query_type) {
      GraphQL::ObjectType.define do
        name "Query"
        field :int, types.Int do
          argument :value, types.Int
          resolve ->(obj, args, ctx) { args[:value] == 13 ? raise("13 is unlucky") : args[:value] }
        end
      end
    }

    let(:schema) {
      spec = self
      GraphQL::Schema.define do
        query(spec.query_type)
        instrument(:field, MultiplyInstrumenter.new(3))
        instrument(:query, StackCheckInstrumenter.new(spec.variable_counter))
        instrument(:query, spec.variable_counter)
      end
    }

    it "can modify field definitions" do
      res = schema.execute(" { int(value: 2) } ")
      assert_equal 6, res["data"]["int"]
    end

    it "can wrap query execution" do
      schema.execute("query getInt($val: Int = 5){ int(value: $val) } ")
      schema.execute("query getInt($val: Int = 5, $val2: Int = 3){ int(value: $val) int2: int(value: $val2) } ")
      assert_equal [:in, 1, :end, :out, :in, 2, :end, :out], variable_counter.counts
    end

    it "runs even when a runtime error occurs" do
      schema.execute("query getInt($val: Int = 5){ int(value: $val) } ")
      assert_raises(RuntimeError) {
        schema.execute("query getInt($val: Int = 13){ int(value: $val) } ")
      }
      assert_equal [:in, 1, :end, :out, :in, 1, :end, :out], variable_counter.counts
    end

    it "can be applied after the fact" do
      res = schema.execute("query { int(value: 2) } ")
      assert_equal 6, res["data"]["int"]

      schema.instrument(:field, MultiplyInstrumenter.new(4))
      res = schema.execute("query { int(value: 2) } ")
      assert_equal 24, res["data"]["int"]
    end

    class CyclicalDependencyInstrumentation
      def initialize(schema)
        @schema = schema
      end

      def instrument(type, field)
        @schema.types # infinite loop
        field
      end
    end

    describe "field instrumenters which cause loops" do
      it "has a nice error message" do
        assert_raises(GraphQL::Schema::CyclicalDefinitionError) do
          schema.redefine {
            instrument(:field, CyclicalDependencyInstrumentation.new(self.target))
          }
        end
      end
    end
  end

  describe "#lazy? / #lazy_method_name" do
    class LazyObj; end
    class LazyObjChild < LazyObj; end

    let(:schema) {
      query_type = GraphQL::ObjectType.define(name: "Query")
      GraphQL::Schema.define do
        query(query_type)
        lazy_resolve(Integer, :itself)
        lazy_resolve(LazyObj, :dup)
      end
    }

    it "returns registered lazy method names by class/superclass, or returns nil" do
      assert_equal :itself, schema.lazy_method_name(68)
      assert_equal true, schema.lazy?(77)
      assert_equal :dup, schema.lazy_method_name(LazyObj.new)
      assert_equal true, schema.lazy?(LazyObj.new)
      assert_equal :dup, schema.lazy_method_name(LazyObjChild.new)
      assert_equal true, schema.lazy?(LazyObjChild.new)
      assert_nil schema.lazy_method_name({})
      assert_equal false, schema.lazy?({})
    end
  end

  describe "#dup" do
    it "copies internal state" do
      schema_1 = schema.graphql_definition
      schema_2 = schema_1.dup
      refute schema_2.types.equal?(schema_1.types)

      refute schema_2.instrumenters.equal?(schema_1.instrumenters)
      assert_equal schema_2.instrumenters, schema_1.instrumenters

      refute schema_2.middleware.equal?(schema_1.middleware)
      assert_equal schema_2.middleware, schema_1.middleware

      schema_2.middleware << ->(*args) { :noop }
      refute_equal schema_2.middleware, schema_1.middleware
    end
  end

  describe "#validate" do
    it "returns errors on the query string" do
      errors = schema.validate("{ cheese(id: 1) { flavor flavor: id } }")
      assert_equal 1, errors.length
      assert_equal "Field 'flavor' has a field conflict: flavor or id?", errors.first.message

      errors = schema.validate("{ cheese(id: 1) { flavor id } }")
      assert_equal [], errors
    end

    it "accepts a list of custom rules" do
      custom_rules = GraphQL::StaticValidation::ALL_RULES - [GraphQL::StaticValidation::FragmentsAreNamed]
      errors = schema.validate("fragment on Cheese { id }", rules: custom_rules)
      assert_equal([], errors)
    end
  end

  describe "#as_json / #to_json" do
    it "returns the instrospection result" do
      result = schema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)
      assert_equal result, schema.as_json
      assert_equal result, JSON.parse(schema.to_json)
    end
  end

  describe "#as_json" do
    it "returns a hash" do
      result = schema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)
      assert_equal result.as_json.class, Hash
    end
  end

  describe "#get_field" do
    it "returns fields by type or type name" do
      field = schema.get_field("Cheese", "id")
      assert_instance_of GraphQL::Field, field
      field_2 = schema.get_field(Dummy::CheeseType, "id")
      assert_equal field, field_2
    end
  end

  describe "class-based schemas" do
    it "delegates to the graphql definition" do
      # Not delegated:
      assert_equal Jazz::Query.graphql_definition, Jazz::Schema.query
      assert Jazz::Schema.respond_to?(:query)
      # Delegated
      assert_equal [], Jazz::Schema.tracers
      assert Jazz::Schema.respond_to?(:tracers)
    end

    it "works with plugins" do
      assert_equal "xyz", Jazz::Schema.metadata[:plugin_key]
    end
  end
end
