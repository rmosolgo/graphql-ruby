# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::TypeReferencesMap do
  let(:fields) {
    [
      Dummy::CheeseType.fields["flavor"],
      Dummy::DairyType.fields["id"],
      Dummy::CowType.fields["name"],
      Dummy::CowType.fields["id"],
      Dummy::CheeseType.fields["similarCheese"]
    ]
  }

  it "it builds a map from a list of fields" do
    result = GraphQL::Schema::TypeReferencesMap.from_fields(fields)
    expected = {
      "String" => [Dummy::CheeseType.fields["flavor"], Dummy::CowType.fields["name"]],
      "ID" => [Dummy::DairyType.fields["id"], Dummy::CowType.fields["id"]],
      "Cheese" => [Dummy::CheeseType.fields["similarCheese"]],
      "DairyAnimal" => [
        Dummy::CheeseType.fields["similarCheese"].arguments["source"],
        Dummy::CheeseType.fields["similarCheese"].arguments["nullableSource"]
      ]
    }
    assert_equal expected, result
  end
end
