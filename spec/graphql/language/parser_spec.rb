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

  describe "implements" do
    it "parses when there are no interfaces" do
      schema = "
        type A {
          a: String
        }
      "

      document = subject.parse(schema)

      assert_equal [], document.definitions[0].interfaces.map(&:name)
    end

    it "parses with leading ampersand" do
      schema = "
        type A implements & B {
          a: String
        }
      "

      document = subject.parse(schema)

      assert_equal ["B"], document.definitions[0].interfaces.map(&:name)
      assert_equal [2, 29], document.definitions[0].interfaces[0].position
    end

    it "parses with leading ampersand and multiple interfaces" do
      schema = "
        type A implements & B & C {
          a: String
        }
      "

      document = subject.parse(schema)

      assert_equal ["B", "C"], document.definitions[0].interfaces.map(&:name)
      assert_equal [2, 29], document.definitions[0].interfaces[0].position
      assert_equal [2, 33], document.definitions[0].interfaces[1].position
    end

    it "parses without leading ampersand" do
      schema = "
        type A implements B {
          a: String
        }
      "

      document = subject.parse(schema)

      assert_equal ["B"], document.definitions[0].interfaces.map(&:name)
      assert_equal [2, 27], document.definitions[0].interfaces[0].position
    end

    it "parses without leading ampersand and multiple interfaces" do
      schema = "
        type A implements B & C {
          a: String
        }
      "

      document = subject.parse(schema)

      assert_equal ["B", "C"], document.definitions[0].interfaces.map(&:name)
      assert_equal [2, 27], document.definitions[0].interfaces[0].position
      assert_equal [2, 31], document.definitions[0].interfaces[1].position
    end

    it "supports the old way of parsing multiple interfaces for backwards compatibility" do
      schema = "
        type A implements B, C {
          a: String
        }
      "

      document = subject.parse(schema)

      assert_equal ["B", "C"], document.definitions[0].interfaces.map(&:name)
      assert_equal [2, 27], document.definitions[0].interfaces[0].position
      assert_equal [2, 30], document.definitions[0].interfaces[1].position
    end
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
