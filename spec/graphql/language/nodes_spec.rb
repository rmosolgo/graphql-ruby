# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Language::Nodes::AbstractNode do
  describe "#filename" do
    it "is set after .parse_file" do
      filename = "spec/support/parser/filename_example.graphql"
      doc = GraphQL.parse_file(filename)
      op = doc.definitions.first
      field = op.selections.first
      arg = field.arguments.first

      assert_equal filename, doc.filename
      assert_equal filename, op.filename
      assert_equal filename, field.filename
      assert_equal filename, arg.filename
    end

    it "is null when parse from string" do
      doc = GraphQL.parse("{ thing }")
      assert_nil doc.filename
    end
  end

  describe "#to_query_tring" do
    let(:document) {
      GraphQL.parse('type Query { a: String! }')
    }

    class CustomPrinter < GraphQL::Language::Printer
      def print_field_definition(print_field_definition)
        "<Field Hidden>"
      end
    end

    it "accepts a custom printer" do
      expected = <<-SCHEMA
type Query {
  <Field Hidden>
}
      SCHEMA
      assert_equal expected.chomp, document.to_query_string(printer: CustomPrinter.new)
    end
  end

  describe "#parent" do
    it "returns the preceeding node" do
      document = GraphQL.parse <<-GRAPHQL
      query DoStuff {
        field1 @directive {
          field2(argument1: { argument2: ENUM_VALUE })
        }
      }
      GRAPHQL

      field2 = document.definitions.first.selections.first.selections.first
      assert_equal "field2", field2.name
      assert_equal "field1", field2.parent.name
      assert_equal "DoStuff", field2.parent.parent.name
      assert_instance_of GraphQL::Language::Nodes::Document, field2.parent.parent.parent
      assert_nil field2.parent.parent.parent.parent

      argument2 = field2.arguments.first.value.arguments.first
      assert_equal "argument2", argument2.name
      assert_instance_of GraphQL::Language::Nodes::InputObject, argument2.parent
      assert_equal "argument1", argument2.parent.parent.name
      assert_equal "field2", argument2.parent.parent.parent.name

      directive = document.definitions.first.selections.first.directives.first
      assert_equal "directive", directive.name
      assert_equal "field1", directive.parent.name
    end
  end

  describe "#path" do
    it "returns the location in the query string" do
      document = GraphQL.parse <<-GRAPHQL
        query DoStuff {
          f1alias: field1 @directive {
            field2(argument1: { argument2: ENUM_VALUE })
          }
        }
      GRAPHQL

      field2 = document.definitions.first.selections.first.selections.first
      assert_equal ["DoStuff", "f1alias", "field2"], field2.path

      argument2 = field2.arguments.first.value.arguments.first
      assert_equal ["DoStuff", "f1alias", "field2", "argument1", "argument2"], argument2.path

      directive = document.definitions.first.selections.first.directives.first
      assert_equal ["DoStuff", "f1alias", "@directive"], directive.path
    end


    it "uses keywords" do
      document = GraphQL.parse <<-GRAPHQL
        mutation {
          f1
        }
      GRAPHQL

      f1 = document.definitions.first.selections.first
      assert_equal ["mutation", "f1"], f1.path
    end

    it "uses keywords for anonymous query" do
      document = GraphQL.parse <<-GRAPHQL
        {
          f1
        }
      GRAPHQL

      f1 = document.definitions.first.selections.first
      assert_equal ["query", "f1"], f1.path
    end

    it "works with schema definitions" do
      document = GraphQL.parse <<-GRAPHQL
      type T {
        field1(arg1: Int = 1): T!
      }

      enum E {
        VALUE @doStuff(dirArg: 1)
      }
      GRAPHQL

      arg1 = document.definitions[0].fields.first.arguments.first
      assert_equal ["type T", "field1", "arg1"], arg1.path

      dir_arg = document.definitions[1].values.first.directives.first.arguments.first
      assert_equal ["enum E", "VALUE", "@doStuff", "dirArg"], dir_arg.path
    end
  end
end
