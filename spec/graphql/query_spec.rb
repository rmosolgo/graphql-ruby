# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Query do
  let(:query_string) { %|
    query getFlavor($cheeseId: Int!) {
      brie: cheese(id: 1)   { ...cheeseFields, taste: flavor },
      cheese(id: $cheeseId)  {
        __typename,
        id,
        ...cheeseFields,
        ... edibleFields,
        ... on Cheese { cheeseKind: flavor },
      }
      fromSource(source: COW) { id }
      fromSheep: fromSource(source: SHEEP) { id }
      firstSheep: searchDairy(product: [{source: SHEEP}]) {
        __typename,
        ... dairyFields,
        ... milkFields
      }
      favoriteEdible { __typename, fatContent }
    }
    fragment cheeseFields on Cheese { flavor }
    fragment edibleFields on Edible { fatContent }
    fragment milkFields on Milk { source }
    fragment dairyFields on AnimalProduct {
       ... on Cheese { flavor }
       ... on Milk   { source }
    }
  |}
  let(:operation_name) { nil }
  let(:max_depth) { nil }
  let(:query_variables) { {"cheeseId" => 2} }
  let(:schema) { Dummy::Schema }
  let(:document) { GraphQL.parse(query_string) }

  let(:query) { GraphQL::Query.new(
    schema,
    query_string,
    variables: query_variables,
    operation_name: operation_name,
    max_depth: max_depth,
  )}
  let(:result) { query.result }

  describe "when passed no query string or document" do
    it 'fails with an ArgumentError' do
      assert_raises(ArgumentError) {
        GraphQL::Query.new(
          schema,
          variables: query_variables,
          operation_name: operation_name,
          max_depth: max_depth,
        )
      }
    end
  end

  describe "when passed a document instance" do
    let(:query) { GraphQL::Query.new(
      schema,
      document: document,
      variables: query_variables,
      operation_name: operation_name,
      max_depth: max_depth,
    )}

    it "runs the query using the already parsed document" do
      expected = {"data"=> {
        "brie" =>   { "flavor" => "Brie", "taste" => "Brie" },
        "cheese" => {
          "__typename" => "Cheese",
          "id" => 2,
          "flavor" => "Gouda",
          "fatContent" => 0.3,
          "cheeseKind" => "Gouda",
        },
        "fromSource" => [{ "id" => 1 }, {"id" => 2}],
        "fromSheep"=>[{"id"=>3}],
        "firstSheep" => { "__typename" => "Cheese", "flavor" => "Manchego" },
        "favoriteEdible"=>{"__typename"=>"Milk", "fatContent"=>0.04},
    }}
    assert_equal(expected, result)
    end
  end

  describe '#result' do
    it "returns fields on objects" do
      expected = {"data"=> {
          "brie" =>   { "flavor" => "Brie", "taste" => "Brie" },
          "cheese" => {
            "__typename" => "Cheese",
            "id" => 2,
            "flavor" => "Gouda",
            "fatContent" => 0.3,
            "cheeseKind" => "Gouda",
          },
          "fromSource" => [{ "id" => 1 }, {"id" => 2}],
          "fromSheep"=>[{"id"=>3}],
          "firstSheep" => { "__typename" => "Cheese", "flavor" => "Manchego" },
          "favoriteEdible"=>{"__typename"=>"Milk", "fatContent"=>0.04},
      }}
      assert_equal(expected, result)
    end

    describe "when it hits null objects" do
      let(:query_string) {%|
        {
          maybeNull {
            cheese {
              flavor,
              similarCheese(source: [SHEEP]) { flavor }
            }
          }
        }
      |}

      it "skips null objects" do
        expected = {"data"=> {
          "maybeNull" => { "cheese" => nil }
        }}
        assert_equal(expected, result)
      end
    end

    describe "after_query hooks" do
      module Instrumenter
        ERROR_LOG = []
        def self.before_query(q); end;
        def self.after_query(q); ERROR_LOG << q.result["errors"]; end;
      end

      let(:schema) {
        Dummy::Schema.redefine {
          instrument(:query, Instrumenter)
        }
      }
      it "can access #result" do
        result
        assert_equal [nil], Instrumenter::ERROR_LOG
      end
    end
  end

  it "uses root_value as the object for the root type" do
    result = GraphQL::Query.new(schema, '{ root }', root_value: "I am root").result
    assert_equal 'I am root', result.fetch('data').fetch('root')
  end

  it "exposes fragments" do
    assert_equal(GraphQL::Language::Nodes::FragmentDefinition, query.fragments["cheeseFields"].class)
  end

  it "exposes the original string" do
    assert_equal(query_string, query.query_string)
  end

  describe "merging fragments with different keys" do
    let(:query_string) { %|
      query getCheeseFieldsThroughDairy {
        ... cheeseFrag3
        dairy {
          ...flavorFragment
          ...fatContentFragment
        }
      }
      fragment flavorFragment on Dairy {
        cheese {
          flavor
        }
        milks {
          id
        }
      }
      fragment fatContentFragment on Dairy {
        cheese {
          fatContent
        }
        milks {
          fatContent
        }
      }

      fragment cheeseFrag1 on Query {
        cheese(id: 1) {
          id
        }
      }
      fragment cheeseFrag2 on Query {
        cheese(id: 1) {
          flavor
        }
      }
      fragment cheeseFrag3 on Query {
        ... cheeseFrag2
        ... cheeseFrag1
      }
    |}

    it "should include keys from each fragment" do
      expected = {"data" => {
        "dairy" => {
          "cheese" => {
            "flavor" => "Brie",
            "fatContent" => 0.19
          },
          "milks" => [
            {
              "id" => "1",
              "fatContent" => 0.04,
            }
          ],
        },
        "cheese" => {
          "id" => 1,
          "flavor" => "Brie"
        },
      }}
      assert_equal(expected, result)
    end
  end

  describe "field argument default values" do
    let(:query_string) {%|
      query getCheeses(
        $search: [DairyProductInput]
        $searchWithDefault: [DairyProductInput] = [{source: COW}]
      ){
        noVariable: searchDairy(product: $search) {
          ... cheeseFields
        }
        noArgument: searchDairy {
          ... cheeseFields
        }
        variableDefault: searchDairy(product: $searchWithDefault) {
          ... cheeseFields
        }
        convertedDefault: fromSource {
          ... cheeseFields
        }
      }
      fragment cheeseFields on Cheese { flavor }
    |}

    it "has a default value" do
      default_source = schema.query.fields["searchDairy"].arguments["product"].default_value[0]["source"]
      assert_equal("SHEEP", default_source)
    end

    describe "when a variable is used, but not provided" do
      it "uses the default_value" do
        assert_equal("Manchego", result["data"]["noVariable"]["flavor"])
      end
    end

    describe "when the argument isn't passed at all" do
      it "uses the default value" do
        assert_equal("Manchego", result["data"]["noArgument"]["flavor"])
      end
    end

    describe "when the variable has a default" do
      it "uses the variable default" do
        assert_equal("Brie", result["data"]["variableDefault"]["flavor"])
      end
    end

    describe "when the variable has a default needing conversion" do
      it "uses the converted variable default" do
        assert_equal([{"flavor" => "Brie"}, {"flavor" => "Gouda"}], result["data"]["convertedDefault"])
      end
    end
  end

  describe "query variables" do
    let(:query_string) {%|
      query getCheese($cheeseId: Int!){
        cheese(id: $cheeseId) { flavor }
      }
    |}

    describe "when they can be coerced" do
      let(:query_variables) { {"cheeseId" => 2.0} }

      it "coerces them on the way in" do
        assert("Gouda", result["data"]["cheese"]["flavor"])
      end
    end

    describe "when they can't be coerced" do
      let(:query_variables) { {"cheeseId" => "2"} }

      it "raises an error" do
        expected = {
          "errors" => [
            {
              "message" => "Variable cheeseId of type Int! was provided invalid value",
              "locations"=>[{ "line" => 2, "column" => 23 }],
              "value" => "2",
              "problems" => [{ "path" => [], "explanation" => 'Could not coerce value "2" to Int' }]
            }
          ]
        }
        assert_equal(expected, result)
      end
    end

    describe "when they aren't provided" do
      let(:query_variables) { {} }

      it "raises an error" do
        expected = {
          "errors" => [
            {
              "message" => "Variable cheeseId of type Int! was provided invalid value",
              "locations" => [{"line" => 2, "column" => 23}],
              "value" => nil,
              "problems" => [{ "path" => [], "explanation" => "Expected value to not be null" }]
            }
          ]
        }
        assert_equal(expected, result)
      end
    end

    describe "when they are non-null and provided a null value" do
      let(:query_variables) { { "cheeseId" => nil } }

      it "raises an error" do
        expected = {
          "errors" => [
            {
              "message" => "Variable cheeseId of type Int! was provided invalid value",
              "locations" => [{"line" => 2, "column" => 23}],
              "value" => nil,
              "problems" => [{ "path" => [], "explanation" => "Expected value to not be null" }]
            }
          ]
        }
        assert_equal(expected, result)
      end
    end

    describe "when they're a string" do
      let(:query_variables) { '{ "var" : 1 }' }
      it "raises an error" do
        assert_raises(ArgumentError) { result }
      end
    end

    describe "default values" do
      let(:query_string) {%|
        query getCheese($cheeseId: Int = 3){
          cheese(id: $cheeseId) { id, flavor }
        }
      |}

      describe "when no value is provided" do
        let(:query_variables) { {} }

        it "uses the default" do
          assert(3, result["data"]["cheese"]["id"])
          assert("Manchego", result["data"]["cheese"]["flavor"])
        end
      end

      describe "when a value is provided" do
        it "uses the provided variable" do
          assert(2, result["data"]["cheese"]["id"])
          assert("Gouda", result["data"]["cheese"]["flavor"])
        end
      end

      describe "when complex values" do
        let(:query_variables) { {"search" => [{"source" => "COW"}]} }
        let(:query_string) {%|
          query getCheeses($search: [DairyProductInput]!){
            cow: searchDairy(product: $search) {
              ... on Cheese {
                flavor
              }
            }
          }
        |}

        it "coerces recursively" do
          assert_equal("Brie", result["data"]["cow"]["flavor"])
        end
      end
    end
  end

  describe "max_depth" do
    let(:query_string) {
      <<-GRAPHQL
      {
        cheese(id: 1) {
          similarCheese(source: SHEEP) {
            similarCheese(source: SHEEP) {
              similarCheese(source: SHEEP) {
                similarCheese(source: SHEEP) {
                  id
                }
              }
            }
          }
        }
      }
      GRAPHQL
    }

    it "defaults to the schema's max_depth" do
      # Constrained by schema's setting of 5
      assert_equal 1, result["errors"].length
    end

    describe "overriding max_depth" do
      let(:max_depth) { 12 }

      it "overrides the schema's max_depth" do
        assert result["data"].key?("cheese")
        assert_equal nil, result["errors"]
      end
    end
  end

  describe "#provided_variables" do
    it "returns the originally-provided object" do
      assert_equal({"cheeseId" => 2}, query.provided_variables)
    end
  end

  describe "parse errors" do
    let(:invalid_query_string) {
      <<-GRAPHQL
        {
          getStuff
          nonsense
          This is broken 1
        }
      GRAPHQL
    }
    it "adds an entry to the errors key" do
      res = schema.execute(" { ")
      assert_equal 1, res["errors"].length
      assert_equal "Unexpected end of document", res["errors"][0]["message"]
      assert_equal [], res["errors"][0]["locations"]

      res = schema.execute(invalid_query_string)
      assert_equal 1, res["errors"].length
      assert_equal %|Parse error on "1" (INT) at [4, 26]|, res["errors"][0]["message"]
      assert_equal({"line" => 4, "column" => 26}, res["errors"][0]["locations"][0])
    end

    it "can be configured to raise" do
      raise_schema = schema.redefine(parse_error: ->(err, ctx) { raise err })
      assert_raises(GraphQL::ParseError) {
        raise_schema.execute(invalid_query_string)
      }
    end
  end

  describe 'NullValue type arguments' do
    let(:schema_definition) {
      <<-GRAPHQL
        type Query {
          foo(id: [ID]): Int
        }
      GRAPHQL
    }
    let(:expected_args) { [] }
    let(:default_resolver) do
      {
        'Query' => { 'foo' => ->(_obj, args, _ctx) { expected_args.push(args); 1 } },
      }
    end
    let(:schema) { GraphQL::Schema.from_definition(schema_definition, default_resolve: default_resolver) }

    it 'sets argument to nil when null is passed' do
      query = <<-GRAPHQL
        {
          foo(id: null)
        }
      GRAPHQL

      schema.execute(query)

      assert(expected_args.first.key?('id'))
      assert_nil(expected_args.first['id'])
    end

    it 'sets argument to nil when nil is passed via variable' do
      query = <<-GRAPHQL
        query baz($id: [ID]) {
          foo(id: $id)
        }
      GRAPHQL

      schema.execute(query, variables: { 'id' => nil })

      assert(expected_args.first.key?('id'))
      assert([nil], expected_args.first['id'])
    end

    it 'sets argument to [nil] when [null] is passed' do
      query = <<-GRAPHQL
        {
          foo(id: [null])
        }
      GRAPHQL

      schema.execute(query)

      assert(expected_args.first.key?('id'))
      assert_equal([nil], expected_args.first['id'])
    end

    it 'sets argument to [nil] when [nil] is passed via variable' do
      query = <<-GRAPHQL
        query baz($id: [ID]) {
          foo(id: $id)
        }
      GRAPHQL

      schema.execute(query, variables: { 'id' => [nil] })

      assert(expected_args.first.key?('id'))
      assert_equal([nil], expected_args.first['id'])
    end
  end
end
