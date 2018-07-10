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

  describe "#visit_method" do
    it "is implemented by all node classes" do
      node_classes = GraphQL::Language::Nodes.constants - [:WrapperType, :NameOnlyNode]
      node_classes.each do |const|
        node_class = GraphQL::Language::Nodes.const_get(const)
        abstract_method = GraphQL::Language::Nodes::AbstractNode.instance_method(:visit_method)
        if node_class.is_a?(Class) && node_class < GraphQL::Language::Nodes::AbstractNode
          concrete_method = node_class.instance_method(:visit_method)
          refute_nil concrete_method.super_method, "#{node_class} overrides #visit_method"
          visit_method_name = "on_" + node_class.name
            .split("::").last
            .gsub(/([a-z\d])([A-Z])/,'\1_\2')     # someThing -> some_Thing
            .downcase
          assert GraphQL::Language::Visitor.method_defined?(visit_method_name), "Language::Visitor has a method for #{node_class} (##{visit_method_name})"
        end
      end
    end
  end
end
