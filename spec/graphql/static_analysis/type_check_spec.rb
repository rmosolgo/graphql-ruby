require "spec_helper"

describe GraphQL::StaticAnalysis::TypeCheck do
  include StaticAnalysisHelpers

  describe "selections" do
    it "requires selections on defined fields" do
      query_string = %|
      {
        nonsenseField
        deepNonsenseField {
          child1
          child2
        }
      }
      |
      assert_errors(
        query_string,
        %|Field "nonsenseField" doesn't exist on "Query"|,
        %|Field "deepNonsenseField" doesn't exist on "Query"|,
      )
    end

    it "requires selections on interfaces and objects"
    focus
    it "doesn't allow selections on unions"

    it "doesn't allow selections on scalars" do
      query_string = %|
      {
        addInt(rhs: 1, lhs: 2) { value }
        addInt(rhs: 1, lhs: 2) { value { value } }
      }
      |
      assert_errors(
        query_string,
        %|Type "Int" can't have selections, see "Result.value"|
      )
    end
  end

  describe "arguments" do
    it "requires defined arguments" do
      query_string = %|
      {
        addInt(right: 1, rhs: 1, lhs: 2)
      }
      |
      assert_errors(
        query_string,
        %|Field "Query.addInt" doesn't accept "right" as an argument|,
      )
    end

    it "requires valid literal inputs"

    it "checks for required arguments" do
      query_string = %|
      {
        addInt(lhs: 2)
        calculate(expression: {add: {lhs: 1, rhs: 2}}) {
          calculate(expression: {add: {rhs: 5}})
        }
      }
      |
      assert_errors(
        query_string,
        %|Required arguments missing from "Query.addInt": "rhs"|,
        %|Required arguments missing from "Operands": "lhs"|,
      )
    end
  end

  describe "variables" do
    it "requires input types"
    it "requires compatible default values"
    it "requires valid usage, even on nested spreads"
  end

  describe "directives" do
    it "requires defined directives"
    it "requires valid locations"
    it "requires defined arguments"
  end

  describe "fragments" do
    it "requires defined, composite types for fragment type conditions"
    it "requires that spreads are possible"
    it "requires that object spreads in object scope are the same type"
    it "requires that object spreads in abstract scope are members of the abstract scope"
    it "requires that abstract spreads in object scope contain the object"
    it "requires that abstract spreads in abstract scopes have some types in common"
  end

  describe "root types" do
    it "requires that they're defined" do
      query_string = %|
      subscription getStuff { things }
      mutation getOtherStuff { things }
      |
      assert_errors(
        query_string,
        %|Root type doesn't exist for operation: "subscription"|,
        %|Root type doesn't exist for operation: "mutation"|,
      )
    end
  end

  describe "error handling" do
    it "can recover from missing type condition"
    it "can recover from missing root type"
    it "can recover from missing field"
    it "can recover from missing argument"
  end
end
