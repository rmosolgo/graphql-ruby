require 'spec_helper'

describe GraphQL::Query::Executor do
  let(:debug) { false }
  let(:operation_name) { nil }
  let(:schema) { DummySchema }
  let(:variables) { {"cheeseId" => 2} }
  let(:result) { schema.execute(
    query_string,
    variables: variables,
    debug: debug,
    operation_name: operation_name,
  )}

  describe "multiple operations" do
    let(:query_string) { %|
      query getCheese1 { cheese(id: 1) { flavor } }
      query getCheese2 { cheese(id: 2) { flavor } }
    |}

    describe "when an operation is named" do
      let(:operation_name) { "getCheese2" }

      it "runs the named one" do
        expected = {
          "data" => {
            "cheese" => {
              "flavor" => "Gouda"
            }
          }
        }
        assert_equal(expected, result)
      end
    end

    describe "when one is NOT named" do
      it "returns an error" do
        expected = {
          "errors" => [
            {"message" => "You must provide an operation name from: getCheese1, getCheese2"}
          ]
        }
        assert_equal(expected, result)
      end
    end
  end

  describe 'maximum query depth' do
    let(:query_string) {%|
      query maxDepth {
        cheese(id: 1) {
          source
          similarCheese(source: COW) {
            flavor
            similarCheese(source: COW) {
              flavor
            }
          }
        }
      }
    |}

    let(:debug) { false }

    let(:result) { schema.execute(
      query_string,
      variables: {},
      debug: debug,
      operation_name: operation_name,
      max_depth: max_depth
    )}

    describe 'when query is too deep' do
      let(:max_depth) { 3 }

      it 'raises a RuntimeError' do
        expected = {"errors"=>[
          {"message"=>"Max query depth was exceeded", "locations"=>[]}
        ]}
        assert_equal(expected, result)
      end
    end

    describe 'when query depth is below maximum' do
      let(:max_depth) { 4 }

      it 'executes normally' do
        expected = {
          "data"=> {
            "cheese" => {
              "source" =>"COW",
              "similarCheese" => {
                "flavor" => "Brie",
                "similarCheese"=> {
                  "flavor" => "Brie"
                }
              }
            }
          }
        }
        assert_equal(expected, result)
      end
    end
  end

  describe 'execution order' do
    let(:query_string) {%|
      mutation setInOrder {
        first:  pushValue(value: 1)
        second: pushValue(value: 5)
        third:  pushValue(value: 2)
        fourth: replaceValues(input: {values: [6,5,4]})
      }
    |}

    it 'executes mutations in order' do
      expected = {"data"=>{
          "first"=> [1],
          "second"=>[1, 5],
          "third"=> [1, 5, 2],
          "fourth"=> [6, 5 ,4],
      }}
      assert_equal(expected, result)
    end
  end


  describe 'fragment resolution' do
    let(:schema) {
      # we will raise if the dairy field is resolved more than one time
      resolved = false

      DummyQueryType = GraphQL::ObjectType.define do
        name "Query"
        field :dairy do
          type DairyType
          resolve -> (t, a, c) {
            raise if resolved
            resolved = true
            DAIRY
          }
        end
      end

      GraphQL::Schema.new(query: DummyQueryType, mutation: MutationType)
    }
    let(:variables) { nil }
    let(:query_string) { %|
      query getDairy {
        dairy {
          id
          ... on Dairy {
            id
          }
          ...repetitiveFragment
        }
      }
      fragment repetitiveFragment on Dairy {
        id
      }
    |}

    it 'resolves each field only one time, even when present in multiple fragments' do
      expected = {"data" => {
        "dairy" => { "id" => "1" }
      }}
      assert_equal(expected, result)
    end

  end


  describe 'runtime errors' do
    let(:query_string) {%| query noMilk { error }|}
    describe 'if debug: false' do
      let(:debug) { false }
      it 'turns into error messages' do
        expected = {"errors"=>[
          {"message"=>"Something went wrong during query execution: This error was raised on purpose"}
        ]}
        assert_equal(expected, result)
      end
    end

    describe 'if debug: true' do
      let(:debug) { true }
      it 'raises error' do
        assert_raises(RuntimeError) { result }
      end
    end

    describe 'if nil is given for a non-null field' do
      let(:query_string) {%| query noMilk { cow { name cantBeNullButIs } }|}
      it 'turns into error message and nulls the entire selection' do
        expected = {
          "data" => { "cow" => nil },
          "errors" => [
            {
              "message" => "Cannot return null for non-nullable field cantBeNullButIs"
            }
          ]
        }
        assert_equal(expected, result)
      end
    end

    describe 'if an execution error is raised for a non-null field' do
      let(:query_string) {%| query noMilk { cow { name cantBeNullButRaisesExecutionError } }|}
      it 'uses provided error message and nulls the entire selection' do
        expected = {
          "data" => { "cow" => nil },
          "errors" => [
            {
              "message" => "BOOM",
              "locations" => [ { "line" => 1, "column" => 28 } ]
            }
          ]
        }
        assert_equal(expected, result)
      end
    end

    describe "if the schema has a rescue handler" do
      before do
        schema.rescue_from(RuntimeError) { "Error was handled!" }
      end

      after do
        # remove the handler from the middleware:
        schema.remove_handler(RuntimeError)
      end

      it "adds to the errors key" do
        expected = {
          "data" => {"error" => nil},
          "errors"=>[
            {
              "message"=>"Error was handled!",
              "locations" => [{"line"=>1, "column"=>17}]
            }
          ]
        }
        assert_equal(expected, result)
      end
    end
  end

  describe "variable coercion" do
    describe "for unspecified with default" do
      let(:query_string) {%| query Q($limit: Int = 2) { milk(id: 1) { flavors(limit: $limit) } } |}

      it "uses the default value" do
        expected = {
          "data" => {
            "milk" => {
              "flavors" => ["Natural", "Chocolate"],
            }
          }
        }
        assert_equal(expected, result)
      end
    end

    describe "for input object type" do
      let(:variables) { {"input" => [{ "source" => "SHEEP" }]} }
      let(:query_string) {%| query Q($input: [DairyProductInput]) { searchDairy(product: $input) { __typename, ... on Cheese { id, source } } } |}
      it "uses the default value" do
        expected = {
          "data" => {
            "searchDairy" => {
              "__typename" => "Cheese",
              "id" => 3,
              "source" => "SHEEP"
            }
          }
        }
        assert_equal(expected, result)
      end
    end

    describe "for required input object fields" do
      let(:variables) { {"input" => {} } }
      let(:query_string) {%| mutation M($input: ReplaceValuesInput!) { replaceValues(input: $input) } |}
      it "returns a variable validation error" do
        expected = {
          "errors"=>[
            {
              "message" => "Variable input of type ReplaceValuesInput! was provided invalid value {}",
              "locations" => [{"line"=>1, "column"=>14}]
            }
          ]
        }
        assert_equal(expected, result)
      end
    end

    describe "for input objects with unknown keys in value" do
      let(:variables) { {"input" => [{ "foo" => "bar" }]} }
      let(:query_string) {%| query Q($input: [DairyProductInput]) { searchDairy(product: $input) { __typename, ... on Cheese { id, source } } } |}
      it "returns a variable validation error" do
        expected = {
          "errors"=>[
            {
              "message" => "Variable input of type [DairyProductInput] was provided invalid value [{\"foo\":\"bar\"}]",
              "locations" => [{"line"=>1, "column"=>11}]
            }
          ]
        }
        assert_equal(expected, result)
      end
    end
  end
end
