# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Language::Nodes::AbstractNode do
  describe ".visit_method" do
    # `.visit_method` is really helpful for generating methods in
    # custom visitor classes -- make sure this API keeps working.
    it "names a method on the visitor class" do
      node_classes = GraphQL::Language::Nodes.constants
        .map { |c| GraphQL::Language::Nodes.const_get(c) }
        .select { |obj| obj.is_a?(Class) && obj < GraphQL::Language::Nodes::AbstractNode }


      node_classes -= [GraphQL::Language::Nodes::WrapperType, GraphQL::Language::Nodes::NameOnlyNode]
      expected_classes = 35
      assert_equal 35, node_classes.size
      tested_classes = 0
      node_classes.each do |node_class|
        expected_method_name = "on_#{GraphQL::Schema::Member::BuildType.underscore(node_class.name.split("::").last)}"
        assert_equal node_class.visit_method.to_s, expected_method_name, "#{node_class} has #{expected_method_name} for visit_method"
        assert GraphQL::Language::Visitor.method_defined?(expected_method_name), "Visitor has ##{expected_method_name}"
        assert GraphQL::Language::StaticVisitor.method_defined?(expected_method_name), "Visitor has ##{expected_method_name}"
        tested_classes += 1
      end
      assert_equal expected_classes, tested_classes, "All classes were tested"
    end
  end

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
          print_string("<Field Hidden>")
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
