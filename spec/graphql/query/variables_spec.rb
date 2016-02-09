require "spec_helper"

describe GraphQL::Query::Variables do
  let(:query_string) {%|
  query getCheese($animals: [DairyAnimal]) {
    cheese(id: 1) {
      similarCheese(source: $animals)
    }
  }
  |}
  let(:ast_variables) { GraphQL.parse(query_string).definitions.first.variables }
  let(:variables) { GraphQL::Query::Variables.new(
    DummySchema,
    ast_variables,
    provided_variables)
  }

  describe "#initialize" do
    describe "coercing inputs" do
      let(:provided_variables) {
        {"animals" => "YAK"}
      }
      it "coerces single items into one-element lists" do
        assert_equal ["YAK"], variables["animals"]
      end
    end
  end
end
