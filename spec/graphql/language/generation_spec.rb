# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Language::Generation do
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
  a: String!
}
      SCHEMA

      assert_equal expected.chomp, GraphQL::Language::Generation.generate(document)
    end

    it "accepts a custom printer" do
      expected = <<-SCHEMA
type Query {
  <Field Hidden>
}
      SCHEMA

      assert_equal expected.chomp, GraphQL::Language::Generation.generate(document, printer: CustomPrinter.new)
    end
  end
end
