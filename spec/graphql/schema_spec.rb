require "spec_helper"

describe GraphQL::Schema do
  let(:schema) { DummySchema }
  let(:relay_schema)  { StarWarsSchema }
  let(:empty_schema) { GraphQL::Schema.define }

  describe "#rescue_from" do
    let(:rescue_middleware) { schema.middleware.first }

    it "adds handlers to the rescue middleware" do
      assert_equal(1, rescue_middleware.rescue_table.length)
      # normally, you'd use a real class, not a symbol:
      schema.rescue_from(:error_class) { "my custom message" }
      assert_equal(2, rescue_middleware.rescue_table.length)
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
            resolve_type ->(obj, ctx) { :whatever }
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
            resolve_type ->(obj, ctx) { :whatever }
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
          resolve -> (obj, args, ctx) { args[:value] }
        end
      end
    }

    let(:schema) {
      spec = self
      GraphQL::Schema.define do
        query(spec.query_type)
        instrument(:field, MultiplyInstrumenter.new(3))
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
      assert_equal [1, 2], variable_counter.counts
    end
  end

  describe "#directives" do
    let(:schema) {
      query_type = GraphQL::ObjectType.define do
        name "Query"
        field :one, types.Int, resolve: -> (o,a,c) { 1 }
      end

      schema_directives = directives

      GraphQL::Schema.define do
        query(query_type)
        directives(schema_directives)
      end
    }

    describe "when @defer is not provided" do
      let(:directives) { [] }
      it "doesn't execute queries with defer" do
        res = schema.execute("{ one @defer }")
        assert_equal nil, res["data"]
        assert_equal 1, res["errors"].length
      end
    end

    describe "when @defer is provided" do
      let(:directives) { ["defer"] }

      it "executes queries with defer" do
        res = schema.execute("{ deferred: one @defer, one }")
        # The deferred field is left out ??
        assert_equal 1, res["data"]["one"]
        assert_equal nil, res["errors"]
      end
    end
  end
end
