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
      "String!" => [Dummy::CheeseType.fields["flavor"]],
      "ID!" => [Dummy::DairyType.fields["id"], Dummy::CowType.fields["id"]],
      "String" => [Dummy::CowType.fields["name"]],
      "Cheese" => [Dummy::CheeseType.fields["similarCheese"]]
    }
    assert_equal expected, result
  end
end
