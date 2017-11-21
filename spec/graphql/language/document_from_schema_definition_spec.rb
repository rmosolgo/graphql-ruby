# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Language::DocumentFromSchemaDefinition do
  let(:schema) { Dummy::Schema }

  let(:subject) { GraphQL::Language::DocumentFromSchemaDefinition }

  describe "#document" do
    it "returns the document AST from the given schema" do
      document = subject.new(schema).document
      idl = document.to_query_string
      schema_from_ast = GraphQL::Schema::BuildFromDefinition.from_definition(idl, default_resolve: {})

      assert_equal GraphQL::Schema::Printer.print_schema(schema), GraphQL::Schema::Printer.print_schema(schema_from_ast)
    end
  end
end
