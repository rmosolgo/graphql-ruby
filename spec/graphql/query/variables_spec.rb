require "spec_helper"

describe GraphQL::Query::Variables do
  let(:query_string) {%|
  query getCheese($animals: [DairyAnimal], $int: Int, $intWithDefault: Int = 10) {
    cheese(id: 1) {
      similarCheese(source: $animals)
    }
  }
  |}
  let(:ast_variables) { GraphQL.parse(query_string).definitions.first.variables }
  let(:variables) { GraphQL::Query::Variables.new(
    DummySchema,
    GraphQL::Schema::Warden.new(DummySchema, GraphQL::Query::NullExcept),
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

    describe "coercing null" do
      let(:provided_variables) {
        {"int" => nil, "intWithDefault" => nil}
      }

      it "null variable" do
        assert_equal nil, variables["int"]
      end

      it "preserves explicit null when variable has a default value" do
        assert_equal nil, variables["intWithDefault"]
      end
    end
  end
end
