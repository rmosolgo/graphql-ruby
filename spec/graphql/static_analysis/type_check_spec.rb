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
          type
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
        %|Arguments for "Query.addInt" are invalid: undefined arguments ("right")|,
      )
    end

    it "requires valid literal inputs" do
      query_string = %|
      {
        badString: addInt(rhs: "1aa", lhs: 2) { value }
        badFloat: addInt(rhs: ENUM, lhs: 2) { value }
      }
      |
      # TODO: check message for input object & directive
      assert_errors(
        query_string,
        %|Argument "rhs" on "addInt" has an invalid value, expected type "Int!" but received "1aa"|,
        %|Argument "rhs" on "addInt" has an invalid value, expected type "Int!" but received ENUM|
      )
    end

    it "checks for required arguments" do
      query_string = %|
      {
        addInt(lhs: 2) { value }
        calculate(expression: {add: {lhs: 1, rhs: 2}}) {
          ... on CalculationSuccess {
            calculate(expression: {add: {rhs: 5}}) { ... on CalculationSuccess { value } }
            value @skip
          }
        }
      }
      |
      assert_errors(
        query_string,
        %|Arguments for "Query.addInt" are invalid: missing required arguments ("rhs")|,
        %|Arguments for "Operands" are invalid: missing required arguments ("lhs")|,
        %|Arguments for "@skip" are invalid: missing required arguments ("if")|,
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
        %|Arguments for "@skip" are invalid: missing required arguments ("if"), undefined arguments ("nonsense")|,
      )
    end
  end

  describe "fragments" do
    it "requires defined, composite types for fragment definition type conditions" do
      query_string = %|
      query {
        addInt(lhs: 1, rhs: 2) {
          ...f1
          ...f2
          ...f3
          ...f4
        }
      }

      fragment f1 on Int { nonsense }
      fragment f2 on Nonsense { nonsense }
      fragment f3 on CalculationResult {
        # This is an error
        value
        # This is ok
        ... on CalculationError { message }
      }
      # This is OK
      fragment f4 on CalculationSuccess { value }
      |

      assert_errors(
        query_string,
        %|Type "Int" can't have selections, see fragment "f1"|,
        %|Type "Nonsense" doesn't exist, so it can't be used as a fragment type|,
        %|Type "CalculationResult" can't have direct selections, use a fragment spread to access members instead, see fragment "f3"|,
      )
    end

    it "requires defined, composite types for inline fragment type conditions" do
      query_string = %|
      query {
        addInt(lhs: 1, rhs: 2) {
          # OK
          ... { __typename }
          ... on CalculationSuccess { value }
          # Not OK
          ... on Int { nonsense }
          ... on Nonsense { nonsense }
          ... on CalculationResult {
            value
            # This is ok
            ... on CalculationError { message }
          }
        }
      }
      |

      assert_errors(
        query_string,
        %|Type "Int" can't have selections, see inline fragment on "Int"|,
        %|Type "Nonsense" doesn't exist, so it can't be used as a fragment type|,
        %|Type "CalculationResult" can't have direct selections, use a fragment spread to access members instead, see inline fragment on "CalculationResult"|,
      )
    end

    it "requires fields for fragment selections and inline fragments" do
      query_string = %|
      query {
        addInt(lhs: 1, rhs: 2) {
          ...f1
          ... on CalculationSuccess { }
        }
      }
      fragment f1 on CalculationSuccess { }
      |

      assert_errors(
        query_string,
        %|Type "CalculationSuccess" must have selections, see fragment "f1"|,
        %|Type "CalculationSuccess" must have selections, see inline fragment on "CalculationSuccess"|,
      )
    end

    it "requires that object spreads in object scope are the same type" do
      query_string = %|
      {
        addInt(lhs: 1, rhs: 2) {
          # OK:
          ...f1
          ... on CalculationSuccess { value }
          # Not OK:
          ...f2
          ... on CalculationError { message }
        }
      }
      fragment f1 on CalculationSuccess { value }
      fragment f2 on CalculationError { message }
      |
      assert_errors(
        query_string,
        %|Can't spread CalculationError inside CalculationSuccess (object types must match), inline fragment on "CalculationError" is invalid|,
        %|Can't spread CalculationError inside CalculationSuccess (object types must match), "...f2" is invalid|,
      )
    end

    it "requires that object spreads in abstract scope are members of the abstract scope" do
      query_string = %|
      {
        calculate(expression: { add: { lhs: 1, rhs: 2 } }) {
          # This is a Union
          # OK
          ... on CalculationSuccess { value }
          ... on CalculationError { message }
          # NOT OK
          ... on Query { addInt(lhs: 1, rhs: 2) { value } }
          ... f1
        }
        intValue(value: 3) {
          # This is an interface
          # OK
          value
          ... on IntegerValue { value }
          # Not OK
          ... on CalculationError { message }
          ... f1
        }
      }

      fragment f1 on Query { intValue(value: 2) { value } }
      |

      assert_errors(
        query_string,
        %|Can't spread Query inside CalculationResult (Query is not a member of CalculationResult), inline fragment on "Query" is invalid|,
        %|Can't spread Query inside CalculationResult (Query is not a member of CalculationResult), "...f1" is invalid|,
        %|Can't spread CalculationError inside Value (CalculationError doesn't implement Value), inline fragment on "CalculationError" is invalid|,
        %|Can't spread Query inside Value (Query doesn't implement Value), "...f1" is invalid|,
      )
    end

    it "requires that abstract spreads in object scope contain the object" do
      query_string = %|
      {
        addInt(lhs: 2, rhs: 2) {
          value
          ... on CalculationResult {
            ... on CalculationError { message }
            ... on CalculationSuccess { value }
          }
          # Not OK, Interface:
          ... on Operation {
            perform(operands: {lhs: 1, rhs: 2}) { ... on CalculationSuccess { value } }
          }
          ... f1
          # Not OK: Union:
          ... on Error {
            ... on CalculationError { message }
          }
          ... f2
        }
      }
      fragment f1 on Operation {
        perform(operands: {lhs: 1, rhs: 2}) { ... on CalculationSuccess { value } }
      }
      fragment f2 on Error {
        ... on CalculationError { message }
      }
      |

      assert_errors(
        query_string,
        %|Can't spread Operation inside CalculationSuccess (CalculationSuccess doesn't implement Operation), "...f1" is invalid|,
        %|Can't spread Operation inside CalculationSuccess (CalculationSuccess doesn't implement Operation), inline fragment on "Operation" is invalid|,
        %|Can't spread Error inside CalculationSuccess (CalculationSuccess isn't a member of Error), inline fragment on "Error" is invalid|,
        %|Can't spread Error inside CalculationSuccess (CalculationSuccess isn't a member of Error), "...f2" is invalid|,
      )
    end

    it "requires that abstract spreads in abstract scopes have some types in common" do
      query_string = %|
      {
        calculate(expression: { add: { lhs: 1, rhs: 2 } }) {
          # OK
          ... on Error {
            ... on CalculationError { message }
          }
          ...f1

          ... on Value {
            # Invalid spreads on an interface:
            ... on Error { __typename }
            ... on Operation { __typename }
          }
          ... on Error {
            # Invalid spreads on a union:
            ...f2
            ...f3
          }
        }
      }

      fragment f1 on Value { __typename }
      fragment f2 on Success { __typename }
      fragment f3 on Operation { __typename }
      |
      assert_errors(
        query_string,
        %|Can't spread Error inside Value (Error doesn't include any members of Value), inline fragment on "Error" is invalid|,
        %|Can't spread Operation inside Value (Operation doesn't include any members of Value), inline fragment on "Operation" is invalid|,
        %|Can't spread Success inside Error (Success doesn't include any members of Error), "...f2" is invalid|,
        %|Can't spread Operation inside Error (Operation doesn't include any members of Error), "...f3" is invalid|,
      )
    end
  end

  describe "root types" do
    it "requires that they're defined" do
      query_string = %|
      subscription getStuff { things }
      mutation getOtherStuff { things }
      |
      assert_errors(
        query_string,
        %|"subscription getStuff" is invalid: root type "subscription" doesn't exist|,
        %|"mutation getOtherStuff" is invalid: root type "mutation" doesn't exist|,
      )
    end
  end
end
