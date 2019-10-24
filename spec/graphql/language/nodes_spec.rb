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

    let(:custom_printer_class) {
      Class.new(GraphQL::Language::Printer) {
        def print_field_definition(print_field_definition)
          "<Field Hidden>"
        end
      }
    }

    it "accepts a custom printer" do
      expected = <<-SCHEMA
type Query {
  <Field Hidden>
}
      SCHEMA
      assert_equal expected.chomp, document.to_query_string(printer: custom_printer_class.new)
    end
  end

  describe "#dup" do
    it "works with adding selections" do
      f = GraphQL::Language::Nodes::Field.new(name: "f")
      # Calling `.children` may populate an internal cache
      assert_equal "f", f.to_query_string, "the original is unchanged"
      assert_equal 0, f.children.size
      assert_equal 0, f.selections.size

      f2 = f.merge(selections: [GraphQL::Language::Nodes::Field.new(name: "__typename")])

      assert_equal "f", f.to_query_string, "the original is unchanged"
      assert_equal 0, f.children.size
      assert_equal 0, f.selections.size

      assert_equal "f {\n  __typename\n}", f2.to_query_string, "the duplicate is updated"
      assert_equal 1, f2.children.size
      assert_equal 1, f2.selections.size
    end
  end
end
