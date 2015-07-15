require 'spec_helper'

class TypeCheckValidator
  def self.checks
    @checks ||= []
  end

  def validate(context)
    self.class.checks.clear
    context.visitor[GraphQL::Nodes::Field] << -> (node, parent) {
      self.class.checks << context.object_types.map(&:name)
    }
  end
end

describe GraphQL::StaticValidation::TypeStack do
  let(:query_string) {%|
    query getCheese {
      cheese(id: 1) { id, ... edibleFields }
    }
    fragment edibleFields on Edible { fatContent }
  |}
  let(:document) { GraphQL.parse(query_string) }
  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, validators: [TypeCheckValidator]) }

  it 'stores up types' do
    validator.validate(document)
    expected = [
      ["Query", "Cheese"],
      ["Query", "Cheese", "Non-Null"],
      ["Edible", "Non-Null"]
    ]
    assert_equal(expected, TypeCheckValidator.checks)
  end
end
