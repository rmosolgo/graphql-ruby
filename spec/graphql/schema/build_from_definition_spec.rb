# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::BuildFromDefinition do
  # Build a schema from `definition` and assert that it
  # prints out the same string.
  # Then return the built schema.
  def build_schema_and_compare_output(definition)
    built_schema = GraphQL::Schema.from_definition(definition)
    assert_equal definition, GraphQL::Schema::Printer.print_schema(built_schema)
    built_schema
  end

  describe '.build' do
    it 'can build a schema with a simple type' do
      schema = <<-SCHEMA
schema {
  query: HelloScalars
}

type HelloScalars {
  bool: Boolean
  float: Float
  id: ID
  int: Int
  str: String!
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'can build a schema with default input object values' do
      schema = <<-SCHEMA
input InputObject {
  a: Int
}

type Query {
  a(input: InputObject = {a: 1}): String
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'can build a schema with directives' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

directive @foo(arg: Int, nullDefault: Int = null) on FIELD

type Hello {
  str: String
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'supports descriptions' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

# This is a directive
directive @foo(
  # It has an argument
  arg: Int
) on FIELD

# With an enum
enum Color {
  BLUE

  # Not a creative color
  GREEN
  RED
}

# What a great type
type Hello {
  anEnum: Color

  # And a field to boot
  str: String
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'maintains built-in directives' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

type Hello {
  str: String
}
      SCHEMA

      built_schema = GraphQL::Schema.from_definition(schema)
      assert_equal ['deprecated', 'include', 'skip'], built_schema.directives.keys.sort
    end

    it 'supports overriding built-in directives' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

directive @skip on FIELD
directive @include on FIELD
directive @deprecated on FIELD_DEFINITION

type Hello {
  str: String
}
      SCHEMA

      built_schema = GraphQL::Schema.from_definition(schema)

      refute built_schema.directives['skip'] == GraphQL::Directive::SkipDirective
      refute built_schema.directives['include'] == GraphQL::Directive::IncludeDirective
      refute built_schema.directives['deprecated'] == GraphQL::Directive::DeprecatedDirective
    end

    it 'supports adding directives while maintaining built-in directives' do
      schema = <<-SCHEMA
schema @custom(thing: true) {
  query: Hello
}

directive @foo(arg: Int) on FIELD
directive @custom(thing: Boolean) on SCHEMA

type Hello {
  str: String
}
      SCHEMA

      built_schema = GraphQL::Schema.from_definition(schema)

      assert built_schema.directives.keys.include?('skip')
      assert built_schema.directives.keys.include?('include')
      assert built_schema.directives.keys.include?('deprecated')
      assert built_schema.directives.keys.include?('foo')
    end

    it 'supports type modifiers' do
      schema = <<-SCHEMA
schema {
  query: HelloScalars
}

type HelloScalars {
  listOfNonNullStrs: [String!]
  listOfStrs: [String]
  nonNullListOfNonNullStrs: [String!]!
  nonNullListOfStrs: [String]!
  nonNullStr: String!
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'supports recursive type' do
      schema = <<-SCHEMA
schema {
  query: Recurse
}

type Recurse {
  recurse: Recurse
  str: String
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'supports two types circular' do
      schema = <<-SCHEMA
schema {
  query: TypeOne
}

type TypeOne {
  str: String
  typeTwo: TypeTwo
}

type TypeTwo {
  str: String
  typeOne: TypeOne
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'supports single argument fields' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

type Hello {
  booleanToStr(bool: Boolean): String
  floatToStr(float: Float): String
  idToStr(id: ID): String
  str(int: Int): String
  strToStr(bool: String): String
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'properly understands connections' do
      schema = <<-SCHEMA
schema {
  query: Type
}

type Organization {
  email: String
}

# The connection type for Organization.
type OrganizationConnection {
  # A list of edges.
  edges: [OrganizationEdge]

  # A list of nodes.
  nodes: [Organization]

  # Information to aid in pagination.
  pageInfo: PageInfo!

  # Identifies the total count of items in the connection.
  totalCount: Int!
}

# An edge in a connection.
type OrganizationEdge {
  # A cursor for use in pagination.
  cursor: String!

  # The item at the end of the edge.
  node: Organization
}

# Information about pagination in a connection.
type PageInfo {
  # When paginating forwards, the cursor to continue.
  endCursor: String

  # When paginating forwards, are there more items?
  hasNextPage: Boolean!

  # When paginating backwards, are there more items?
  hasPreviousPage: Boolean!

  # When paginating backwards, the cursor to continue.
  startCursor: String
}

type Type {
  name: String
  organization(
    # The login of the organization to find.
    login: String!
  ): Organization

  # A list of organizations the user belongs to.
  organizations(
    # Returns the elements in the list that come after the specified cursor.
    after: String

    # Returns the elements in the list that come before the specified cursor.
    before: String

    # Returns the first _n_ elements from the list.
    first: Int

    # Returns the last _n_ elements from the list.
    last: Int
  ): OrganizationConnection!
}
      SCHEMA

      built_schema = build_schema_and_compare_output(schema.chop)
      obj = built_schema.types["Type"]
      refute obj.fields["organization"].connection?
      assert obj.fields["organizations"].connection?
    end

    it 'supports simple type with multiple arguments' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

type Hello {
  str(bool: Boolean, int: Int): String
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'supports simple type with interface' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

type Hello implements WorldInterface {
  str: String
}

interface WorldInterface {
  str: String
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'supports simple output enum' do
      schema = <<-SCHEMA
schema {
  query: OutputEnumRoot
}

enum Hello {
  WORLD
}

type OutputEnumRoot {
  hello: Hello
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'supports simple input enum' do
      schema = <<-SCHEMA
schema {
  query: InputEnumRoot
}

enum Hello {
  WORLD
}

type InputEnumRoot {
  str(hello: Hello): String
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'supports multiple value enum' do
      schema = <<-SCHEMA
schema {
  query: OutputEnumRoot
}

enum Hello {
  RLD
  WO
}

type OutputEnumRoot {
  hello: Hello
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'supports simple union' do
      schema = <<-SCHEMA
schema {
  query: Root
}

union Hello = World

type Root {
  hello: Hello
}

type World {
  str: String
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'supports multiple union' do
      schema = <<-SCHEMA
schema {
  query: Root
}

union Hello = WorldOne | WorldTwo

type Root {
  hello: Hello
}

type WorldOne {
  str: String
}

type WorldTwo {
  str: String
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'supports custom scalar' do
      schema = <<-SCHEMA
schema {
  query: Root
}

scalar CustomScalar

type Root {
  customScalar: CustomScalar
}
      SCHEMA

      built_schema = build_schema_and_compare_output(schema.chop)
      custom_scalar = built_schema.types["CustomScalar"]
      assert_equal true, custom_scalar.valid_isolated_input?("anything")
      assert_equal true, custom_scalar.valid_isolated_input?(12345)
    end

    it 'supports input object' do
      schema = <<-SCHEMA
schema {
  query: Root
}

input Input {
  int: Int
  nullDefault: Int = null
}

type Root {
  field(in: Input): String
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'supports simple argument field with default value' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

enum Color {
  BLUE
  RED
}

type Hello {
  hello(color: Color = RED): String
  nullable(color: Color = null): String
  str(int: Int = 2): String
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'supports simple type with mutation' do
      schema = <<-SCHEMA
schema {
  query: HelloScalars
  mutation: Mutation
}

type HelloScalars {
  bool: Boolean
  int: Int
  str: String
}

type Mutation {
  addHelloScalars(bool: Boolean, int: Int, str: String): HelloScalars
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'supports simple type with mutation and default values' do
      schema = <<-SCHEMA
enum Color {
  BLUE
  RED
}

type Mutation {
  hello(color: Color = RED, int: Int, nullDefault: Int = null, str: String): String
}

type Query {
  str: String
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'supports simple type with subscription' do
      schema = <<-SCHEMA
schema {
  query: HelloScalars
  subscription: Subscription
}

type HelloScalars {
  bool: Boolean
  int: Int
  str: String
}

type Subscription {
  subscribeHelloScalars(bool: Boolean, int: Int, str: String): HelloScalars
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'supports unreferenced type implementing referenced interface' do
      schema = <<-SCHEMA
type Concrete implements Iface {
  key: String
}

interface Iface {
  key: String
}

type Query {
  iface: Iface
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'supports unreferenced type implementing referenced union' do
      schema = <<-SCHEMA
type Concrete {
  key: String
}

type Query {
  union: Union
}

union Union = Concrete
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'supports @deprecated' do
      schema = <<-SCHEMA
enum MyEnum {
  OLD_VALUE @deprecated
  OTHER_VALUE @deprecated(reason: "Terrible reasons")
  VALUE
}

type Query {
  enum: MyEnum
  field1: String @deprecated
  field2: Int @deprecated(reason: "Because I said so")
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'supports empty types' do
      schema = <<-SCHEMA
type Query {
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it "tracks original AST node" do
      schema_definition = <<-GRAPHQL
schema @custom(thing: true) {
  query: Query
}

enum Enum {
  VALUE
}

type Query {
  field(argument: String): String
  deprecatedField(argument: String): String @deprecated(reason: "Test")
}

interface Interface {
  field(argument: String): String
}

union Union = Query

scalar Scalar

input Input {
  argument: String
}

directive @Directive (
  # Argument
  argument: String
) on SCHEMA

type Type implements Interface {
  field(argument: String): String
}
      GRAPHQL

      schema = GraphQL::Schema.from_definition(schema_definition)

      assert_equal [1, 1], schema.ast_node.position
      assert_equal [1, 8], schema.ast_node.directives.first.position
      assert_equal [5, 1], schema.types["Enum"].ast_node.position
      assert_equal [6, 3], schema.types["Enum"].values["VALUE"].ast_node.position
      assert_equal [9, 1], schema.types["Query"].ast_node.position
      assert_equal [10, 3], schema.types["Query"].fields["field"].ast_node.position
      assert_equal [10, 9], schema.types["Query"].fields["field"].arguments["argument"].ast_node.position
      assert_equal [11, 45], schema.types["Query"].fields["deprecatedField"].ast_node.directives[0].position
      assert_equal [11, 57], schema.types["Query"].fields["deprecatedField"].ast_node.directives[0].arguments[0].position
      assert_equal [14, 1], schema.types["Interface"].ast_node.position
      assert_equal [15, 3], schema.types["Interface"].fields["field"].ast_node.position
      assert_equal [15, 9], schema.types["Interface"].fields["field"].arguments["argument"].ast_node.position
      assert_equal [18, 1], schema.types["Union"].ast_node.position
      assert_equal [20, 1], schema.types["Scalar"].ast_node.position
      assert_equal [22, 1], schema.types["Input"].ast_node.position
      assert_equal [23, 3], schema.types["Input"].arguments["argument"].ast_node.position
      assert_equal [26, 1], schema.directives["Directive"].ast_node.position
      assert_equal [28, 3], schema.directives["Directive"].arguments["argument"].ast_node.position
      assert_equal [31, 22], schema.types["Type"].ast_node.interfaces[0].position
    end
  end

  describe 'Failures' do
    it 'Requires a schema definition or Query type' do
      schema = <<-SCHEMA
type Hello {
  bar: Bar
}
SCHEMA
      err = assert_raises(GraphQL::Schema::InvalidDocumentError) do
        GraphQL::Schema.from_definition(schema)
      end
      assert_equal 'Must provide schema definition with query type or a type named Query.', err.message
    end

    it 'Allows only a single schema definition' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

schema {
  query: Hello
}

type Hello {
  bar: Bar
}
SCHEMA

      err = assert_raises(GraphQL::Schema::InvalidDocumentError) do
        GraphQL::Schema.from_definition(schema)
      end
      assert_equal 'Must provide only one schema definition.', err.message
    end

    it 'Requires a query type' do
      schema = <<-SCHEMA
schema {
  mutation: Hello
}

type Hello {
  bar: Bar
}
SCHEMA

      err = assert_raises(GraphQL::Schema::InvalidDocumentError) do
        GraphQL::Schema.from_definition(schema)
      end
      assert_equal 'Must provide schema definition with query type or a type named Query.', err.message
    end

    it 'Unknown type referenced' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

type Hello {
  bar: Bar
}
SCHEMA

      err = assert_raises(GraphQL::Schema::InvalidDocumentError) do
        GraphQL::Schema.from_definition(schema)
      end
      assert_equal 'Type "Bar" not found in document.', err.message
    end

    it 'Unknown type in interface list' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

type Hello implements Bar {
  str: String
}
SCHEMA

      err = assert_raises(GraphQL::Schema::InvalidDocumentError) do
        GraphQL::Schema.from_definition(schema)
      end
      assert_equal 'Type "Bar" not found in document.', err.message
    end

    it 'Unknown type in union list' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

union TestUnion = Bar

type Hello { testUnion: TestUnion }
SCHEMA

      err = assert_raises(GraphQL::Schema::InvalidDocumentError) do
        GraphQL::Schema.from_definition(schema)
      end
      assert_equal 'Type "Bar" not found in document.', err.message
    end

    it 'Unknown query type' do
      schema = <<-SCHEMA
schema {
  query: Wat
}

type Hello {
  str: String
}
SCHEMA

      err = assert_raises(GraphQL::Schema::InvalidDocumentError) do
        GraphQL::Schema.from_definition(schema)
      end
      assert_equal 'Specified query type "Wat" not found in document.', err.message
    end

    it 'Unknown mutation type' do
      schema = <<-SCHEMA
schema {
  query: Hello
  mutation: Wat
}

type Hello {
  str: String
}
SCHEMA

      err = assert_raises(GraphQL::Schema::InvalidDocumentError) do
        GraphQL::Schema.from_definition(schema)
      end
      assert_equal 'Specified mutation type "Wat" not found in document.', err.message
    end

    it 'Unknown subscription type' do
      schema = <<-SCHEMA
schema {
  query: Hello
  mutation: Wat
  subscription: Awesome
}

type Hello {
  str: String
}

type Wat {
  str: String
}
SCHEMA

      err = assert_raises(GraphQL::Schema::InvalidDocumentError) do
        GraphQL::Schema.from_definition(schema)
      end
      assert_equal 'Specified subscription type "Awesome" not found in document.', err.message
    end

    it 'Does not consider operation names' do
      schema = <<-SCHEMA
schema {
  query: Foo
}

query Foo { field }
SCHEMA

      err = assert_raises(GraphQL::Schema::InvalidDocumentError) do
        GraphQL::Schema.from_definition(schema)
      end
      assert_equal 'Specified query type "Foo" not found in document.', err.message
    end

    it 'Does not consider fragment names' do
      schema = <<-SCHEMA
schema {
  query: Foo
}

fragment Foo on Type { field }
SCHEMA

      err = assert_raises(GraphQL::Schema::InvalidDocumentError) do
        GraphQL::Schema.from_definition(schema)
      end
      assert_equal 'Specified query type "Foo" not found in document.', err.message
    end
  end

  describe "executable schema with resolver maps" do
    class Something
      def capitalize(args)
        args[:word].upcase
      end
    end

    let(:definition) {
      <<-GRAPHQL
        scalar Date
        scalar UndefinedScalar
        type Something { capitalize(word:String!): String }
        type A { a: String }
        type B { b: String }
        union Thing = A | B
        type Query {
          hello: Something
          thing: Thing
          add_week(in: Date!): Date!
          undefined_scalar(str: String, int: Int): UndefinedScalar
        }
      GRAPHQL
    }

    let(:resolvers) {
      {
        Date: {
          coerce_input: ->(val, ctx) {
            Time.at(Float(val))
          },
          coerce_result: ->(val, ctx) {
            val.to_f
          }
        },
        resolve_type: ->(type, obj, ctx) {
          return ctx.schema.types['A']
        },
        Query: {
          add_week: ->(o,a,c) {
            raise "No Time" unless a[:in].is_a? Time
            a[:in]
          },
          hello: ->(o,a,c) {
            Something.new
          },
          thing: ->(o,a,c) {
            OpenStruct.new({a: "a"})
          },
          undefined_scalar: ->(o,a,c) {
            a.values.first
          }
        }
      }
    }

    let(:schema) { GraphQL::Schema.from_definition(definition, default_resolve: resolvers) }

    it "resolves unions"  do
      result = schema.execute("query { thing { ... on A { a } } }")
      assert_equal(result.to_json,'{"data":{"thing":{"a":"a"}}}')
    end

    it "resolves scalars" do
      result = schema.execute("query { add_week(in: 392277600.0) }")
      assert_equal(result.to_json,'{"data":{"add_week":392277600.0}}')
    end

    it "passes args from graphql to the object"  do
      result = schema.execute("query { hello { capitalize(word: \"hello\") }}")
      assert_equal(result.to_json,'{"data":{"hello":{"capitalize":"HELLO"}}}')
    end

    it "handles undefined scalar resolution with identity function" do
      result = schema.execute <<-GRAPHQL
        {
          str: undefined_scalar(str: "abc")
          int: undefined_scalar(int: 123)
        }
      GRAPHQL

      assert_equal({ "str" => "abc", "int" => 123 }, result["data"])
    end
  end

  describe "executable schemas from string" do
    let(:schema_defn) {
      <<-GRAPHQL
        type Todo {text: String, from_context: String}
        type Query { all_todos: [Todo]}
        type Mutation { todo_add(text: String!): Todo}
      GRAPHQL
    }

    Todo = Struct.new(:text, :from_context)

    class RootResolver
      attr_accessor :todos

      def initialize
        @todos = [Todo.new("Pay the bills.")]
      end

      def all_todos
        @todos
      end

      def todo_add(args, ctx) # this is a method and accepting arguments
        todo = Todo.new(args[:text], ctx[:context_value])
        @todos << todo
        todo
      end
    end

    it "calls methods with args if args are defined" do
      schema = GraphQL::Schema.from_definition(schema_defn)
      root_values = RootResolver.new
      schema.execute("mutation { todoAdd: todo_add(text: \"Buy Milk\") { text } }", root_value: root_values, context: {context_value: "bar"})
      result = schema.execute("query { allTodos: all_todos { text, from_context } }", root_value: root_values)
      assert_equal(result.to_json, '{"data":{"allTodos":[{"text":"Pay the bills.","from_context":null},{"text":"Buy Milk","from_context":"bar"}]}}')
    end

    describe "hash of resolvers with defaults" do
      let(:todos) { [Todo.new("Pay the bills.")] }
      let(:schema) { GraphQL::Schema.from_definition(schema_defn, default_resolve: resolve_hash) }
      let(:resolve_hash) {
        h = base_hash
        h["Query"] ||= {}
        h["Query"]["all_todos"] = ->(obj, args, ctx) { obj }
        h["Mutation"] ||= {}
        h["Mutation"]["todo_add"] = ->(obj, args, ctx) {
          todo = Todo.new(args[:text], ctx[:context_value])
          obj << todo
          todo
        }
        h
      }

      let(:base_hash) {
        # Fallback is to resolve by sending the field name
        Hash.new { |h, k| h[k] = Hash.new { |h2, k2| ->(obj, args, ctx) { obj.public_send(k2) } } }
      }

      it "accepts a hash of resolve functions" do
        schema.execute("mutation { todoAdd: todo_add(text: \"Buy Milk\") { text } }", context: {context_value: "bar"}, root_value: todos)
        result = schema.execute("query { allTodos: all_todos { text, from_context } }", root_value: todos)
        assert_equal(result.to_json, '{"data":{"allTodos":[{"text":"Pay the bills.","from_context":null},{"text":"Buy Milk","from_context":"bar"}]}}')
      end
    end

    describe "custom resolve behavior" do
      class AppResolver
        def initialize
          @todos = [Todo.new("Pay the bills.")]
          @resolves = {
            "Query" => {
              "all_todos" => ->(obj, args, ctx) { @todos },
            },
            "Mutation" => {
              "todo_add" => ->(obj, args, ctx) {
                todo = Todo.new(args[:text], ctx[:context_value])
                @todos << todo
                todo
              },
            },
            "Todo" => {
              "text" => ->(obj, args, ctx) { obj.text },
              "from_context" => ->(obj, args, ctx) { obj.from_context },
            }
          }
        end

        def call(type, field, obj, args, ctx)
          @resolves
            .fetch(type.name)
            .fetch(field.name)
            .call(obj, args, ctx)
        end
      end

      it "accepts a default_resolve callable" do
        schema = GraphQL::Schema.from_definition(schema_defn, default_resolve: AppResolver.new)
        schema.execute("mutation { todoAdd: todo_add(text: \"Buy Milk\") { text } }", context: {context_value: "bar"})
        result = schema.execute("query { allTodos: all_todos { text, from_context } }")
        assert_equal(result.to_json, '{"data":{"allTodos":[{"text":"Pay the bills.","from_context":null},{"text":"Buy Milk","from_context":"bar"}]}}')
      end
    end

    describe "custom parser behavior" do
      module BadParser
        ParseError = Class.new(StandardError)

        def self.parse(string)
          raise ParseError
        end
      end

      it 'accepts a parser callable' do
        assert_raises(BadParser::ParseError) do
          GraphQL::Schema.from_definition(schema_defn, parser: BadParser)
        end
      end
    end
  end
end
