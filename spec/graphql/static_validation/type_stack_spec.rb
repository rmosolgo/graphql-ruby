# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::TypeStack do
  let(:query_string) {%|
    query getCheese {
      cheese(id: 1) { id, ... edibleFields }
    }
    fragment edibleFields on Edible { fatContent @skip(if: false)}
  |}

  it "stores up types" do
    document = GraphQL.parse(query_string)
    visitor = GraphQL::Language::Visitor.new(document)
    type_stack = GraphQL::StaticValidation::TypeStack.new(Dummy::Schema, visitor)
    checks = []
    visitor[GraphQL::Language::Nodes::Field].enter << ->(node, parent) {
      checks << type_stack.object_types.map {|t| t.graphql_name || t.kind.name }
    }
    visitor.visit

    expected = [
      ["Query", "Cheese"],
      ["Query", "Cheese", "NON_NULL"],
      ["Edible", "NON_NULL"]
    ]
    assert_equal(expected, checks)
  end
end
