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
  str: String!
  int: Int
  float: Float
  id: ID
  bool: Boolean
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
  RED

  # Not a creative color
  GREEN
  BLUE
}

# What a great type
type Hello {
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
schema {
  query: Hello
}

directive @foo(arg: Int) on FIELD

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
  nonNullStr: String!
  listOfStrs: [String]
  listOfNonNullStrs: [String!]
  nonNullListOfStrs: [String]!
  nonNullListOfNonNullStrs: [String!]!
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
  str: String
  recurse: Recurse
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
  str(int: Int): String
  floatToStr(float: Float): String
  idToStr(id: ID): String
  booleanToStr(bool: Boolean): String
  strToStr(bool: String): String
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'supports simple type with multiple arguments' do
      schema = <<-SCHEMA
schema {
  query: Hello
}

type Hello {
  str(int: Int, bool: Boolean): String
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
  WO
  RLD
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
      assert_equal true, custom_scalar.valid_input?("anything", PermissiveWarden)
      assert_equal true, custom_scalar.valid_input?(12345, PermissiveWarden)
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
  RED
  BLUE
}

type Hello {
  str(int: Int = 2): String
  hello(color: Color = RED): String
  nullable(color: Color = null): String
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
  str: String
  int: Int
  bool: Boolean
}

type Mutation {
  addHelloScalars(str: String, int: Int, bool: Boolean): HelloScalars
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
    end

    it 'supports simple type with mutation and default values' do
      schema = <<-SCHEMA
enum Color {
  RED
  BLUE
}

type Mutation {
  hello(str: String, int: Int, color: Color = RED, nullDefault: Int = null): String
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
  str: String
  int: Int
  bool: Boolean
}

type Subscription {
  subscribeHelloScalars(str: String, int: Int, bool: Boolean): HelloScalars
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
  VALUE
  OLD_VALUE @deprecated
  OTHER_VALUE @deprecated(reason: "Terrible reasons")
}

type Query {
  field1: String @deprecated
  field2: Int @deprecated(reason: "Because I said so")
  enum: MyEnum
}
      SCHEMA

      build_schema_and_compare_output(schema.chop)
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
end
