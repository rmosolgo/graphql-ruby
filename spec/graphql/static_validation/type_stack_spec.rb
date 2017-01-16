# frozen_string_literal: true
require "spec_helper"

class TypeCheckValidator
  def self.checks
    @checks ||= []
  end

  def validate(context)
    self.class.checks.clear
    context.visitor[GraphQL::Language::Nodes::Field] << ->(node, parent) {
      self.class.checks << context.object_types.map {|t| t.name || t.kind.name }
    }
  end
end

describe GraphQL::StaticValidation::TypeStack do
  let(:query_string) {%|
    query getCheese {
      cheese(id: 1) { id, ... edibleFields }
    }
    fragment edibleFields on Edible { fatContent @skip(if: false)}
  |}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: Dummy::Schema, rules: [TypeCheckValidator]) }
  let(:query) { GraphQL::Query.new(Dummy::Schema, query_string) }


  it "stores up types" do
    validator.validate(query)
    expected = [
      ["Query", "Cheese"],
      ["Query", "Cheese", "NON_NULL"],
      ["Edible", "NON_NULL"]
    ]
    assert_equal(expected, TypeCheckValidator.checks)
  end
end
