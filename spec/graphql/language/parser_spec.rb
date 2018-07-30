# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Language::Parser do
  subject { GraphQL::Language::Parser }

  describe "anonymous fragment extension" do
    let(:document) { GraphQL.parse(query_string) }
    let(:query_string) {%|
      fragment on NestedType @or(something: "ok") {
        anotherNestedField
      }
    |}

    let(:fragment) { document.definitions.first }

    it "creates an anonymous fragment definition" do
      assert fragment.is_a?(GraphQL::Language::Nodes::FragmentDefinition)
      assert_nil fragment.name
      assert_equal 1, fragment.selections.length
      assert_equal "NestedType", fragment.type.name
      assert_equal 1, fragment.directives.length
      assert_equal [2, 7], fragment.position
    end
  end

  describe "string description" do
    it "is parsed for scalar definitions" do
      document = subject.parse <<-GRAPHQL
        "Thing description"
        scalar Thing
      GRAPHQL

      thing_defn = document.definitions[0]
      assert_equal "Thing", thing_defn.name
      assert_equal "Thing description", thing_defn.description
    end

    it "is parsed for object definitions, field definitions, and input value definitions" do
      document = subject.parse <<-GRAPHQL
      "Thing description"
      type Thing {
        "field description"
        field("arg description" arg: Stuff): Stuff
      }
      GRAPHQL

      thing_defn = document.definitions[0]
      assert_equal "Thing", thing_defn.name
      assert_equal "Thing description", thing_defn.description

      field_defn = thing_defn.fields[0]
      assert_equal "field", field_defn.name
      assert_equal "field description", field_defn.description

      arg_defn = field_defn.arguments[0]
      assert_equal "arg", arg_defn.name
      assert_equal "arg description", arg_defn.description
    end

    it "is parsed for interface definitions" do
      document = subject.parse <<-GRAPHQL
        "Thing description"
        interface Thing {}
      GRAPHQL

      thing_defn = document.definitions[0]
      assert_equal "Thing", thing_defn.name
      assert_equal "Thing description", thing_defn.description
    end

    it "is parsed for union definitions" do
      document = subject.parse <<-GRAPHQL
        "Thing description"
        union Thing = Int | String
      GRAPHQL

      thing_defn = document.definitions[0]
      assert_equal "Thing", thing_defn.name
      assert_equal "Thing description", thing_defn.description
    end

    it "is parsed for enum definitions and enum value definitions" do
      document = subject.parse <<-GRAPHQL
        "Thing description"
        enum Thing {
          "VALUE description"
          VALUE
        }
      GRAPHQL

      thing_defn = document.definitions[0]
      assert_equal "Thing", thing_defn.name
      assert_equal "Thing description", thing_defn.description

      value_defn = thing_defn.values[0]
      assert_equal "VALUE", value_defn.name
      assert_equal "VALUE description", value_defn.description
    end

    it "is parsed for directive definitions" do
      document = subject.parse <<-GRAPHQL
      "thing description" directive @thing on FIELD
      GRAPHQL

      thing_defn = document.definitions[0]
      assert_equal "thing", thing_defn.name
      assert_equal "thing description", thing_defn.description
    end
  end

  it "parses empty arguments" do
    strings = [
      "{ field { inner } }",
      "{ field() { inner }}",
    ]
    strings.each do |query_str|
      doc = subject.parse(query_str)
      field = doc.definitions.first.selections.first
      assert_equal 0, field.arguments.length
      assert_equal 1, field.selections.length
    end
  end

  it "parses the test schema" do
    schema = Dummy::Schema
    schema_string = GraphQL::Schema::Printer.print_schema(schema)
    document = subject.parse(schema_string)
    assert_equal schema_string, document.to_query_string
  end

  describe ".parse_file" do
    it "assigns filename to all nodes" do
      example_filename = "spec/support/parser/filename_example.graphql"
      doc = GraphQL.parse_file(example_filename)
      assert_equal example_filename, doc.filename
      field = doc.definitions[0].selections[0].selections[0]
      assert_equal example_filename, field.filename
    end

    it "raises errors with filename" do
      error_filename = "spec/support/parser/filename_example_error_1.graphql"
      err = assert_raises(GraphQL::ParseError) {
        GraphQL.parse_file(error_filename)
      }

      assert_includes err.message, error_filename

      error_filename_2 = "spec/support/parser/filename_example_error_2.graphql"
      err_2 = assert_raises(GraphQL::ParseError) {
        GraphQL.parse_file(error_filename_2)
      }

      assert_includes err_2.message, error_filename_2
      assert_includes err_2.message, "3, 11"

    end
  end

  it "serves traces" do
    TestTracing.clear
    GraphQL.parse("{ t: __typename }", tracer: TestTracing)
    traces = TestTracing.traces
    assert_equal 2, traces.length
    lex_trace, parse_trace = traces

    assert_equal "{ t: __typename }", lex_trace[:query_string]
    assert_equal "lex", lex_trace[:key]
    assert_instance_of Array, lex_trace[:result]

    assert_equal "{ t: __typename }", parse_trace[:query_string]
    assert_equal "parse", parse_trace[:key]
    assert_instance_of GraphQL::Language::Nodes::Document, parse_trace[:result]
  end
end
