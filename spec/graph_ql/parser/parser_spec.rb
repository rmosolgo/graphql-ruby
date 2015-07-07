require 'spec_helper'

describe GraphQL::Parser do
  let(:parser) { GraphQL::PARSER }

  it 'parses documents' do
    assert(parser.parse_with_debug(%|
    # let's make a big query:
    # a read-only:
    query getStuff {id, name @if: true}
    # a mutation:
    mutation changeStuff($override: true, $cucumber: {id: 7, name: "Cucumber"}) @veggie, @healthy: true {
      # change the cucumber
      changeStuff(thing: $cucumber) {
        id,
        name,
        ... on Species { color },
        ... family # background info, of course
      }
    }

    # a fragment:
    fragment family on Species {
      family {
        name,                                       # name of the family
        members(first: 3, query: {isPlant: true}) # some of the other examples
      }
    }

    fragment nonsense on NonsenseType { bogus }
    |), 'gets a document with lots of comments')

    assert(parser.parse_with_debug("{fields, only, inThisOne}"), 'fetch-only query')
  end


  it 'parses operation definitions' do
    assert(parser.operation_definition.parse_with_debug(%|{id, name, ...people}|), "just a selection")
    assert(parser.operation_definition.parse_with_debug(%|query personStuff {id, name, ...people, ... stuff}|), "named fetch")
    assert(parser.operation_definition.parse_with_debug(%|query personStuff @flagDirective {id, name, ...people}|), "with a directive")
    assert(parser.operation_definition.parse_with_debug(%|mutation changeStuff($stuff: 1, $things: true) {id, name, ...people}|), "just a selection")
  end

  it 'parses fragment definitions' do
    assert(parser.fragment_definition.parse_with_debug(%|fragment nutritionFacts on Food { fat, sodium, carbohydrates, vitamins { a, b } }|))
    assert(parser.fragment_definition.parse_with_debug(%|fragment nutritionFacts on Food @directive: "argument" { fat, sodium, carbohydrates, vitamins { a, b } }|), 'gets directives')
  end

  it 'parses selections' do
    assert(parser.selections.parse_with_debug(%|{id, name, people { count }}|), 'gets nested fields')
    assert(parser.selections.parse_with_debug(%|{id, ... myFragment }|), 'gets fragment spreads')
    assert(parser.selections.parse_with_debug(%|{id, ... on User @myFlag { name, photo } }|), 'gets inline fragments')
    assert(parser.selections.parse_with_debug(%|{id @if: true, ... myFragment @if: $something}|), 'gets directives')
  end

  it 'parses directives' do
    assert(parser.directives.parse_with_debug("@doSomething"), 'gets without argument')
    assert(parser.directives.parse_with_debug('@doSomething: "forSomeReason"'), 'gets with argument')
    assert(parser.directives.parse_with_debug('@myFlag, @doSomething: "forSomeReason"'), 'gets multiple')
  end

  it 'parses fields' do
    assert(parser.field.parse_with_debug(%|myField { name, id }|), 'gets subselections')
    assert(parser.field.parse_with_debug(%{myAlias: myField}), 'gets an alias')
    assert(parser.field.parse_with_debug(%{myField(intKey: 1, floatKey: 1.1e5)}), 'gets arguments')
    assert(parser.field.parse_with_debug(%{myAlias: myField(stringKey: "my_string", boolKey: false, objKey: {key : true})}), 'gets alias and arguments')
    assert(parser.field.parse_with_debug(%|myField @withFlag, @if: true { name, id }|), 'gets with directive')
  end

  describe 'value' do
    it 'gets ints' do
      assert(parser.value.parse_with_debug("100"), 'positive')
      assert(parser.value.parse_with_debug("-9"), 'negative')
      assert(parser.value.parse_with_debug("0"), 'zero')
    end

    it 'gets floats' do
      assert(parser.value.parse_with_debug("1.14"), 'no exponent')
      assert(parser.value.parse_with_debug("6.7e-9"), 'negative exponent')
      assert(parser.value.parse_with_debug("0.4e12"), 'exponent')
    end

    it 'gets booleans' do
      assert(parser.value.parse_with_debug("true"))
      assert(parser.value.parse_with_debug("false"))
    end

    it 'gets strings' do
      assert(parser.value.parse_with_debug('"my string"'))
    end

    it 'gets arrays' do
      assert(parser.value.parse_with_debug('[true, 1, "my string", -5.123e56]'), 'array of values')
      assert(parser.value.parse_with_debug('[]'), 'empty array')
      assert(parser.value.parse_with_debug('[[true, 1], ["my string", -5.123e56]]'), 'array of arrays')
    end

    it 'gets variables' do
      assert(parser.value.parse_with_debug('$myVariable'), 'gets named variables')
    end

    it 'gets objects' do
      assert(parser.value.parse_with_debug('{name: "tomato", calories: 50}'), 'gets scalar values')
      assert(parser.value.parse_with_debug('{listOfValues: [1, 2, [3]], nestedObject: {nestedKey: "nested{Value}"}}'), 'gets complex values')
      assert(parser.value.parse_with_debug('{variableKey: $variableValue}'), 'gets variables')
    end
  end
end
