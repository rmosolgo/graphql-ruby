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

    it "requires selections on composite types" do
      query_string = %|
      {
        operation(type: ADDITION) {
          perform(operands: {lhs: 1, rhs: 2}) { ... on CalculationSuccess { value } }
          perform(operands: {lhs: 1, rhs: 2}) { ... on CalculationSuccess { } }
          perform(operands: {lhs: 1, rhs: 2})
          ... operationFields
        }

        operation(type: SUBTRACTION)

      }
      fragment operationFields on Operation { }
      |

      assert_errors(
        query_string,
        %|Type "CalculationResult" must have selections on a member type, see "Operation.perform"|,
        %|Type "Operation" must have selections, see "Query.operation"|,
        %|Type "CalculationSuccess" must have selections, see inline fragment on "CalculationSuccess"|,
        %|Type "Operation" must have selections, see fragment "operationFields"|,
      )
    end

    it "doesn't allow selections on unions" do
      query_string = %|
      {
        okCalculate: calculate(expression: {add: {lhs: 1, rhs: 2}}) {
          # typename is ok on Unions
          __typename
          ... on CalculationSuccess {
            value
          }
          ... on CalculationError {
            message
          }
        }
        badCalculate: calculate(expression: {add: {lhs: 1, rhs: 2}}) {
          value
        }
      }
      |

      assert_errors(
        query_string,
        %|Type "CalculationResult" can't have direct selections, use a fragment spread to access members instead, see "Query.calculate"|
      )
    end

    it "doesn't allow selections on scalars" do
      query_string = %|
      {
        addInt(rhs: 1, lhs: 2) { value }
        addInt(rhs: 1, lhs: 2) { value { value } }
      }
      |
      assert_errors(
        query_string,
        %|Type "Int" can't have selections, see "CalculationSuccess.value"|
      )
    end
  end

  describe "arguments" do
    it "requires defined arguments" do
      query_string = %|
      {
        addInt(right: 1, rhs: 1, lhs: 2) { value }
      }
      |
      assert_errors(
        query_string,
        %|Field "Query.addInt" doesn't accept "right" as an argument|,
      )
    end

    it "requires valid literal inputs" do
      query_string = %|
      {
        badString: addInt(rhs: "1aa", lhs: 2) { value }
        badFloat: addInt(rhs: ENUM, lhs: 2) { value }
      }
      |
      assert_errors(
        query_string,
        %|Argument "rhs" on field "addInt" has an invalid value, expected type "Int!" but received "1aa"|,
        %|Argument "rhs" on field "addInt" has an invalid value, expected type "Int!" but received ENUM|
      )
    end

    it "checks for required arguments" do
      query_string = %|
      {
        addInt(lhs: 2) { value }
        calculate(expression: {add: {lhs: 1, rhs: 2}}) {
          ... on CalculationSuccess {
            calculate(expression: {add: {rhs: 5}}) { ... on CalculationSuccess { value } }
          }
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
    it "requires defined, valid input types" do
      query_string = %|
      query AddStuff(
        $leftA: Operation,
        $rightA: Int!,
        $leftB: Nonsense,
        $rightB: Int = 5,
      ) {
        addInt(lhs: $leftA, rhs: $rightA) { value }
        addInt(lhs: $leftB, rhs: $rightB) { value }
      }
      |

      assert_errors(
        query_string,
        %|Type "Operation" for "$leftA" isn't a valid input (must be INPUT_OBJECT, SCALAR, or ENUM, not INTERFACE)|,
        %|Unknown type "Nonsense" can't be used for variable "$leftB"|,
      )
    end

    it "requires compatible default values" do
      query_string = %|
      query AddStuff(
        $leftA: Operation = 1
        $rightA: Int! = 3
        $leftB: Int = 5.0
        $rightB: Int = "5"
        $expressionGood: Expression = {add: {lhs: 1, rhs: 2}}
        $expressionBad:  Expression = {add: {lhs: 1.0, rhs: true}}
      ) {
        addInt(lhs: $leftA, rhs: $rightA) { value }
        addInt(lhs: $leftB, rhs: $rightB) { value }
        calculate(expression: $expressionGood) {
          ... on CalculationSuccess {
            calculate(expression: $expressionBad) { ... on CalculationSuccess { value } }
          }
        }
      }
      |
      assert_errors(
        query_string,
        # This one should _not_ get an error for the default value:
        %|Type "Operation" for "$leftA" isn't a valid input (must be INPUT_OBJECT, SCALAR, or ENUM, not INTERFACE)|,
        %|Non-null variable "$rightA" can't have a default value|,
        %|Variable "$expressionBad" default value {add: {lhs: 1.0, rhs: true}} doesn't match type Expression|,
        %|Variable "$rightB" default value "5" doesn't match type Int|,
      )
    end

    it "requires valid usage, even on nested spreads" do
      query_string = %|
      query AddStuff(
        $leftA: Float = 3.0,
        $rightA: Int!,
        $leftB: Int,
        $rightB: Int = 5,
      ) {
        addInt(lhs: $leftA, rhs: $rightA) { value }
        ... frag1
      }

      query AddStuff2(
        $leftB: Int!
        $rightB: OperationName
        $listOfInts: [[Int]]!
        $operationName: OperationName
      ) {
        ... frag2
        ... frag3
      }
      fragment frag1 on Query { ... frag2 }
      fragment frag2 on Query {
        addInt(lhs: $leftB, rhs: $rightB) { value }
      }
      fragment frag3 on Query {
        ... on Query {
          ... {
            reduce(ints: $listOfInts, operation: $operationName)
          }
        }
      }
      |

      assert_errors(
        query_string,
        %|Type mismatch on variable "$leftA" and argument "lhs" (Float / Int!)|,
        %|Nullability mismatch on variable "$leftB" and argument "lhs" (Int / Int!)|,
        %|List dimension mismatch on variable "$listOfInts" and argument "ints" ([[Int]]! / [Int!]!)|,
        %|Nullability mismatch on variable "$operationName" and argument "operation" (OperationName / OperationName!)|,
        # One usage of `$rightB` is correct
        %|Type mismatch on variable "$rightB" and argument "rhs" (OperationName / Int!)|,
      )
    end
  end

  describe "directives" do
    it "requires defined directives" do
      query_string = %|
      {
        addInt(lhs: 2, rhs: 1) { value @nonsense(if: true) }
      }
      |
      assert_errors(
        query_string,
        %|Directive "@nonsense" is not defined|
      )
    end

    it "requires valid locations" do
      query_string = %|
      query doStuff @skip(if: true) {
        ... frag
      }
      fragment frag on Query @include(if: true) {
        addInt(lhs: 2, rhs: 1) { value }
      }
      |

      assert_errors(
        query_string,
        %|Directive "@skip" can't be applied to queries (allowed: fields, fragment spreads, inline fragments)|,
        %|Directive "@include" can't be applied to fragment definitions (allowed: fields, fragment spreads, inline fragments)|,
      )
    end

    it "requires defined arguments" do
      query_string = %|
      {
        addInt(lhs: 2, rhs: 1) @skip(if: false) { value @skip(nonsense: true) }
      }|

      assert_errors(
        query_string,
        %|Directive "@skip" doesn't accept "nonsense" as an argument|
      )
    end
  end

  describe "fragments" do
    it "requires defined, composite types for fragment type conditions"
    it "requires fields for fragment selections"
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
end
