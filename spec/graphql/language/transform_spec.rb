require 'spec_helper'

describe GraphQL::Language::Transform do
  def get_result(query_string, parse: nil, debug: false)
    # send parse: :value to do something less than a document
    parser = parse ? GraphQL::PARSER.send(parse) : GraphQL::PARSER
    raw_tree = parser.parse_with_debug(query_string)
    transformed_result = GraphQL::TRANSFORM.apply(raw_tree)
    # send debug: true to see parsing & transforming output
    if debug
      p raw_tree.inspect
      p transformed_result.inspect
    end
    transformed_result
  end

  it 'transforms documents' do
    query = %|
      # you can retrieve data:
      query someInfo($var: [Int!] = [1,2,3]) {
        me {
          name, favorite_food,
          ...personInfo
          someStuff(vars: [1,2,3])
          someOtherStuff(input: {ints: [1,2,3]})
          someEmptyStuff(emptyObj: {}, emptySpaceObj: { })
          evenMoreStuff(arg: [[1]])
        }
      }

      # assign fragments:
      fragment personInfo on Person {
        birthdate, name # with fields
        hobbies(names: [])
      }

      fragment petInfo on Pet { isHousebroken, species } # all on one line

      # and also mutations
      mutation changePetInfo($id: Int = 5, $info: [Dog]) {
        changePetName(id: $id, info: $info) {
          name,
          ... petInfo,
        }
      }
    |
    res = get_result(query, debug: false)
    assert_equal(4, res.definitions.length)

    res = get_result("{ me {id, birthdate} } # query shorthand")
    assert_equal(1, res.definitions.length)
    assert_equal("me", res.definitions.first.selections.first.name)
  end

  it 'transforms operation definitions' do
    res = get_result("query someInfo { a, b, c }", parse: :operation_definition)
    assert_equal("query", res.operation_type)
    assert_equal("someInfo", res.name)
    assert_equal(3, res.selections.length)

    res = get_result(
    "mutation changeThings(
        $var: Float = 4.5E+6,
        $arr: [Int]!
      ) @flag, @skip(if: 1) {
        changeThings(var: $var) { a,b,c }
      }", parse: :operation_definition)
    assert_equal("mutation", res.operation_type)
    assert_equal("var", res.variables.first.name)
    assert_equal("Float", res.variables.first.type.name)
    assert_equal(4_500_000.0, res.variables.first.default_value)
    assert_equal("arr", res.variables.last.name)
    assert_equal(3, res.variables.last.line)
    assert_equal(10, res.variables.last.col)
    assert_equal("Int", res.variables.last.type.of_type.of_type.name)
    assert_equal(2, res.directives.length)
  end

  it 'transforms fragment definitions' do
    res = get_result("fragment someFields on SomeType @flag1, @flag2 { id, name }", parse: :fragment_definition)
    assert_equal("someFields", res.name)
    assert_equal("SomeType", res.type)
    assert_equal(2, res.directives.length)
    assert_equal(2, res.selections.length)
  end

  it 'transforms selections' do
    res = get_result("{ id, ...petStuff @flag, ... on Pet { isHousebroken }, name }", parse: :selections)
    expected_classes = [GraphQL::Language::Nodes::Field, GraphQL::Language::Nodes::FragmentSpread, GraphQL::Language::Nodes::InlineFragment, GraphQL::Language::Nodes::Field]
    assert_equal(expected_classes, res.map(&:class))
  end

  it 'transforms fields' do
    res = get_result(%|best_pals: friends(first: 3, coolnessLevel: SO_COOL, query: {nice: {very: true}}, emptyStr: "")|, parse: :field)
    assert_equal(GraphQL::Language::Nodes::Field, res.class)
    assert_equal(1, res.line)
    assert_equal(1, res.col)
    assert_equal("friends", res.name)
    assert_equal("best_pals", res.alias)
    assert_equal("first", res.arguments[0].name)
    assert_equal(3, res.arguments[0].value)
    assert_equal("SO_COOL", res.arguments[1].value.name)
    assert_equal({"nice" => {"very" => true}}, res.arguments[2].value.to_h)

    res = get_result('me @flag, @include(if: "\"something\"") {name, id}', parse: :field)
    assert_equal("me", res.name)
    assert_equal(nil, res.alias)
    assert_equal(2, res.directives.length)
    assert_equal("flag", res.directives.first.name)
    assert_equal('"something"', res.directives.last.arguments.first.value)
    assert_equal(2, res.selections.length)
  end

  it 'transforms input objects' do
    res_one_pair    = get_result(%q|{one: 1}|, parse: :value_input_object)
    res_two_pair    = get_result(%q|{first: "Apple", second: "Banana"}|, parse: :value_input_object)
    res_empty       = get_result(%q|{}|, parse: :value_input_object)
    res_empty_space = get_result(%q|{ }|, parse: :value_input_object)

    assert_equal('one', res_one_pair.arguments[0].name)
    assert_equal(1    , res_one_pair.arguments[0].value)

    assert_equal('first' , res_two_pair.arguments[0].name)
    assert_equal('Apple' , res_two_pair.arguments[0].value)
    assert_equal('second', res_two_pair.arguments[1].name)
    assert_equal('Banana', res_two_pair.arguments[1].value)

    assert_equal([], res_empty.arguments)
    assert_equal([], res_empty_space.arguments)
  end

  it 'transforms directives' do
    res = get_result('@doSomething(vigorously: "\"true\u0025\"")', parse: :directive)
    assert_equal("doSomething", res.name, 'gets the name without @')
    assert_equal("vigorously", res.arguments.first.name)
    assert_equal('"true%"', res.arguments.first.value)

    res = get_result("@someFlag", parse: :directive)
    assert_equal("someFlag", res.name)
    assert_equal([], res.arguments, 'gets [] if no args')
  end

  it 'transforms unnamed operations' do
    assert_equal(1, get_result("query { me }").definitions.length)
    assert_equal(1, get_result("mutation { touch }").definitions.length)
  end

  it 'transforms escaped characters' do
    res = get_result("{quoted: \"\\\" \\\\ \\/ \\b \\f \\n \\r \\t\"}", parse: :value_input_object)
    assert_equal("\" \\ / \b \f \n \r \t", res.arguments[0].value)
  end
end
