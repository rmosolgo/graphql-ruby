# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::VariableUsagesAreAllowed do
  include StaticValidationHelpers

  let(:query_string) {'
    query getCheese(
        $goodInt: Int = 1,
        $okInt: Int!,
        $badInt: Int,
        $badStr: String!,
        $goodAnimals: [DairyAnimal!]!,
        $badAnimals: [DairyAnimal]!,
        $deepAnimals: [[DairyAnimal!]!]!,
        $goodSource: DairyAnimal!,
    ) {
      goodCheese:   cheese(id: $goodInt)  { source }
      okCheese:     cheese(id: $okInt)    { source }
      badCheese:    cheese(id: $badInt)   { source }
      badStrCheese: cheese(id: $badStr)   { source }
      cheese(id: 1) {
        similarCheese(source: $goodAnimals) { source }
        other: similarCheese(source: $badAnimals) { source }
        tooDeep: similarCheese(source: $deepAnimals) { source }
        nullableCheese(source: $goodAnimals) { source }
        deeplyNullableCheese(source: $deepAnimals) { source }
      }

      milk(id: 1) {
        flavors(limit: $okInt)
      }

      searchDairy(product: [{source: $goodSource}]) {
        ... on Cheese { id }
      }
    }
  '}

  it "finds variables used as arguments but don't match the argument's type" do
    assert_equal(4, errors.length)
    expected = [
      {
        "message"=>"Nullability mismatch on variable $badInt and argument id (Int / Int!)",
        "locations"=>[{"line"=>14, "column"=>28}],
        "path"=>["query getCheese", "badCheese", "id"],
        "extensions"=>{"code"=>"variableMismatch", "variableName"=>"badInt", "typeName"=>"Int", "argumentName"=>"id", "errorMessage"=>"Nullability mismatch"}
      },
      {
        "message"=>"Type mismatch on variable $badStr and argument id (String! / Int!)",
        "locations"=>[{"line"=>15, "column"=>28}],
        "path"=>["query getCheese", "badStrCheese", "id"],
        "extensions"=>{"code"=>"variableMismatch", "variableName"=>"badStr", "typeName"=>"String!", "argumentName"=>"id", "errorMessage"=>"Type mismatch"}
      },
      {
        "message"=>"Nullability mismatch on variable $badAnimals and argument source ([DairyAnimal]! / [DairyAnimal!]!)",
        "locations"=>[{"line"=>18, "column"=>30}],
        "path"=>["query getCheese", "cheese", "other", "source"],
        "extensions"=>{"code"=>"variableMismatch", "variableName"=>"badAnimals", "typeName"=>"[DairyAnimal]!", "argumentName"=>"source", "errorMessage"=>"Nullability mismatch"}
      },
      {
        "message"=>"List dimension mismatch on variable $deepAnimals and argument source ([[DairyAnimal!]!]! / [DairyAnimal!]!)",
        "locations"=>[{"line"=>19, "column"=>32}],
        "path"=>["query getCheese", "cheese", "tooDeep", "source"],
        "extensions"=>{"code"=>"variableMismatch", "variableName"=>"deepAnimals", "typeName"=>"[[DairyAnimal!]!]!", "argumentName"=>"source", "errorMessage"=>"List dimension mismatch"}
      }
    ]
    assert_equal(expected, errors)
  end

  describe "input objects that are out of place" do
    let(:query_string) { <<-GRAPHQL
      query getCheese($id: ID!) {
        cheese(id: {blah: $id} ) {
          __typename @nonsense(id: {blah: $id})
          nonsense(id: {blah: {blah: $id}})
        }
      }
    GRAPHQL
    }

    it "adds an error" do
      assert_equal 3, errors.length
      assert_equal "Argument 'id' on Field 'cheese' has an invalid value ({blah: $id}). Expected type 'Int!'.", errors[0]["message"]
    end
  end

  describe "list-type variables" do
    let(:schema) {
      GraphQL::Schema.from_definition <<-GRAPHQL
      input ImageSize {
        height: Int
        width: Int
        scale: Int
      }

      type Query {
        imageUrl(height: Int, width: Int, size: ImageSize, sizes: [ImageSize!]): String!
        sizedImageUrl(sizes: [ImageSize!]!): String!
      }
      GRAPHQL
    }

    describe "nullability mismatch" do
      let(:query_string) {
        <<-GRAPHQL
        # This variable _should_ be [ImageSize!]
        query ($sizes: [ImageSize]) {
          imageUrl(sizes: $sizes)
        }
        GRAPHQL
      }

      it "finds invalid inner definitions" do
        assert_equal 1, errors.size
        expected_message = "Nullability mismatch on variable $sizes and argument sizes ([ImageSize] / [ImageSize!])"
        assert_equal [expected_message], errors.map { |e| e["message"] }
      end
    end

    describe "list dimension mismatch" do
      let(:query_string) {
        <<-GRAPHQL
        query ($sizes: [ImageSize]) {
          imageUrl(sizes: [$sizes])
        }
        GRAPHQL
      }

      it "finds invalid inner definitions" do
        assert_equal 1, errors.size
        expected_message = "List dimension mismatch on variable $sizes and argument sizes ([[ImageSize]]! / [ImageSize!])"
        assert_equal [expected_message], errors.map { |e| e["message"] }
      end
    end

    describe 'list is in the argument' do
      let(:query_string) {
        <<-GRAPHQL
        query ($size: ImageSize!) {
          imageUrl(sizes: [$size])
        }
        GRAPHQL
      }

      it "is a valid query" do
        assert_equal 0, errors.size
      end

      describe "mixed with invalid literals" do
        let(:query_string) {
          <<-GRAPHQL
          query ($size: ImageSize!) {
            imageUrl(sizes: [$size, 1, true])
          }
          GRAPHQL
        }

        it "is an invalid query" do
          assert_equal 1, errors.size
        end
      end

      describe "mixed with invalid variables" do
        let(:query_string) {
          <<-GRAPHQL
          query ($size: ImageSize!, $wrongSize: Boolean!) {
            imageUrl(sizes: [$size, $wrongSize])
          }
          GRAPHQL
        }

        it "is an invalid query" do
          assert_equal 1, errors.size
        end
      end

      describe "mixed with valid literals and invalid variables" do
        let(:query_string) {
          <<-GRAPHQL
          query ($size: ImageSize!, $wrongSize: Boolean!) {
            imageUrl(sizes: [$size, {height: 100} $wrongSize])
          }
          GRAPHQL
        }

        it "is an invalid query" do
          assert_equal 1, errors.size
        end
      end
    end

    describe 'argument contains a list with literal values' do
      let(:query_string) {
        <<-GRAPHQL
        query  {
          imageUrl(sizes: [{height: 100, width: 100, scale: 1}])
        }
        GRAPHQL
      }

      it "is a valid query" do
        assert_equal 0, errors.size
      end
    end

    describe 'argument contains a list with both literal and variable values' do
      let(:query_string) {
        <<-GRAPHQL
        query($size1: ImageSize!, $size2: ImageSize!)  {
          imageUrl(sizes: [{height: 100, width: 100, scale: 1}, $size1, {height: 1920, width: 1080, scale: 2}, $size2])
        }
        GRAPHQL
      }

      it "is a valid query" do
        assert_equal 0, errors.size
      end
    end

    describe "variable in non-null list" do
      let(:query_string) {
        <<-GRAPHQL
        # This should work
        query ($size: ImageSize!) {
          sizedImageUrl(sizes: [$size])
        }
        GRAPHQL
      }

      it "is allowed" do
        assert_equal [], errors
      end
    end

    describe "nullability mismatch in non-null list" do
      let(:query_string) {
        <<-GRAPHQL
        query ($sizes: [ImageSize!]) {
          sizedImageUrl(sizes: $sizes)
        }
        GRAPHQL
      }

      it "gives the right error" do
        err =  "Nullability mismatch on variable $sizes and argument sizes ([ImageSize!] / [ImageSize!]!)"
        assert_equal [err], errors.map { |e| e["message"]}
      end
    end
  end

  describe "for input properties" do
    class InputVariableSchema < GraphQL::Schema
      class Input < GraphQL::Schema::InputObject
        argument(:id, String)
      end

      class FooMutation < GraphQL::Schema::Mutation
        field(:foo, String, hash_key: :foo)
        argument(:input, Input)

        def resolve(input:)
          { foo: input.id }
        end
      end

      class Mutation < GraphQL::Schema::Object
        field(:foo_mutation, mutation: FooMutation)
      end

      mutation(Mutation)
    end

    it "gives a proper error" do
      res1 = InputVariableSchema.execute("mutation($id: String) { fooMutation(input: { id: $id }) { foo } }")
      assert_equal ["Nullability mismatch on variable $id and argument id (String / String!)"], res1["errors"].map { |e| e["message"] }

      res2 = InputVariableSchema.execute("mutation($id: String!) { fooMutation(input: { id: $id }) { foo } }", variables: { id: "abc" })
      refute res2.key?("errors")
      assert_equal "abc", res2["data"]["fooMutation"]["foo"]
    end
  end

  describe "with error limiting" do
    describe("disabled") do
      let(:args) {
        { max_errors: nil }
      }

      it "does not limit the number of errors" do
        assert_equal(error_messages.length, 4)
        assert_equal(error_messages, [
          "Nullability mismatch on variable $badInt and argument id (Int / Int!)",
          "Type mismatch on variable $badStr and argument id (String! / Int!)",
          "Nullability mismatch on variable $badAnimals and argument source ([DairyAnimal]! / [DairyAnimal!]!)",
          "List dimension mismatch on variable $deepAnimals and argument source ([[DairyAnimal!]!]! / [DairyAnimal!]!)"
        ])
      end
    end

    describe("enabled") do
      let(:args) {
        { max_errors: 1 }
      }

      it "does limit the number of errors" do
        assert_equal(error_messages.length, 1)
        assert_equal(error_messages, [
          "Nullability mismatch on variable $badInt and argument id (Int / Int!)"
        ])
      end
    end
  end

  describe "variables used in fragments" do
    let(:schema) { Class.new(Dummy::Schema) { allow_legacy_invalid_variable_usages(false) } }

    describe "when the fragment comes before the operation" do
      let(:query_string) {'
        fragment cheeseFields on Cheese {
          similarCheese(source: $animals) { id }
        }

        query getCheese($animals: Boolean) {
          cheese(id: 1) { ...cheeseFields }
        }
      '}

      it "checks the usage against the operation" do
        expected = [
          {
            "message"=>"Type mismatch on variable $animals and argument source (Boolean / [DairyAnimal!]!)",
            "locations"=>[{"line"=>3, "column"=>25}],
            "path"=>["fragment cheeseFields", "similarCheese", "source"],
            "extensions"=>{"code"=>"variableMismatch", "variableName"=>"animals", "typeName"=>"Boolean", "argumentName"=>"source", "errorMessage"=>"Type mismatch"}
          },
        ]
        assert_equal(expected, errors)
      end
    end

    describe "when the fragment is used through another fragment" do
      let(:query_string) {'
        fragment innerFields on Cheese {
          similarCheese(source: $animals) { id }
        }

        fragment outerFields on Cheese {
          ...innerFields
        }

        query getCheese($animals: Boolean) {
          cheese(id: 1) { ...outerFields }
        }
      '}

      it "checks the usage against the operation" do
        assert_equal ["Type mismatch on variable $animals and argument source (Boolean / [DairyAnimal!]!)"], error_messages
      end
    end

    describe "when many operations use the fragment" do
      let(:query_string) {'
        query getCheese1($id: Boolean) { ...cheeseFields }
        query getCheese2($id: Int!) { ...cheeseFields }
        query getCheese3($id: String) { ...cheeseFields }
        query getCheese4($id: Boolean) { ...cheeseFields }

        fragment cheeseFields on Query {
          cheese(id: $id) { id }
        }
      '}

      it "checks the usage against each operation, without duplicate errors" do
        assert_equal [
          "Type mismatch on variable $id and argument id (Boolean / Int!)",
          "Type mismatch on variable $id and argument id (String / Int!)",
        ], error_messages
      end
    end
  end

  describe "variables in nested list literals" do
    it "checks each variable against the list items at its depth" do
      schema = GraphQL::Schema.from_definition("type Query { f(ll: [[String]], lln: [[String!]!]): String }")
      schema.allow_legacy_invalid_variable_usages(false)
      query_str = 'query($a: Boolean, $b: String, $c: [String], $d: String) { f(ll: [[$a], [$b], $c]) x: f(lln: [[$d]]) }'
      assert_equal [
        "Type mismatch on variable $a and argument ll ([[Boolean]!]! / [[String]])",
        "Nullability mismatch on variable $d and argument lln ([[String]!]! / [[String!]!])",
      ], schema.validate(query_str).map(&:message)
    end
  end

  describe "variables with a null default value" do
    let(:schema) { Class.new(Dummy::Schema) { allow_legacy_invalid_variable_usages(false) } }

    let(:query_string) {'
      query getCheese($nullId: Int = null, $id: Int = 1) {
        nullCheese: cheese(id: $nullId) { id }
        cheese(id: $id) { id }
      }
    '}

    it "doesn't treat them as non-null" do
      assert_equal ["Nullability mismatch on variable $nullId and argument id (Int / Int!)"], error_messages
    end
  end

  describe "allow_legacy_invalid_variable_usages" do
    let(:schema) { GraphQL::Schema.from_definition("type Query { f(s: String!): Query g(i: Int!): Query x: String }") }

    # Previous versions didn't check `$s` (the fragment comes before the operation) or `$i` (`= null`), but they checked `$j`.
    let(:query_str) { <<~GRAPHQL }
      fragment F on Query { f(s: $s) { x } }
      query Q($s: Boolean, $i: Int = null, $j: Boolean) { ...F g(i: $i) { x } y: g(i: $j) { x } }
    GRAPHQL

    let(:j_error) { "Type mismatch on variable $j and argument i (Boolean / Int!)" }

    it "warns by default" do
      res = nil
      stdout, _stderr = capture_io do
        res = schema.validate(query_str)
      end
      assert_equal [j_error], res.map(&:message)
      expected_warning = [
        "GraphQL-Ruby encountered an invalid variable usage in this query: `$s` (at 2:9) for argument `s` (at 1:25).",
        "This will return an error in future GraphQL-Ruby versions, as per the GraphQL specification",
        "Learn about migrating here: https://graphql-ruby.org/api-doc/#{GraphQL::VERSION}/GraphQL/Schema.html#allow_legacy_invalid_variable_usages-class_method"
      ].join("\n")
      assert_includes stdout, expected_warning
      assert_includes stdout, "invalid variable usage in this query: `$i` (at 2:22) for argument `i` (at 2:60)."
    end

    it "calls the handler when legacy is enabled" do
      calls = []
      legacy_schema = Class.new(schema) do
        allow_legacy_invalid_variable_usages(true)
        define_singleton_method(:legacy_invalid_variable_usages) do |query, variable_definition, argument|
          calls << [query.class, variable_definition.name, argument.name, argument.position]
          variable_definition.name == "s" ? nil : "Don't use $#{variable_definition.name} here"
        end
      end

      res = legacy_schema.validate(query_str)
      assert_equal ["Don't use $i here", j_error], res.map(&:message)
      assert_equal [[GraphQL::Query, "i", "i", [2, 60]], [GraphQL::Query, "s", "s", [1, 25]]], calls
    end

    it "adds errors when legacy is disabled" do
      future_schema = Class.new(schema) { allow_legacy_invalid_variable_usages(false) }
      assert_equal [
        "Nullability mismatch on variable $i and argument i (Int / Int!)",
        j_error,
        "Type mismatch on variable $s and argument s (Boolean / String!)",
      ], future_schema.validate(query_str).map(&:message)
    end

    it "inherits allow_legacy_invalid_variable_usages" do
      base_schema = Class.new(schema) { allow_legacy_invalid_variable_usages(true) }
      ext_schema = Class.new(base_schema)
      assert ext_schema.allow_legacy_invalid_variable_usages
    end
  end

  describe "non-null arguments with default values" do
    it "doesn't require a value in the query" do
      schema_graphql = <<~GRAPHQL
        type Query {
          songs(sort: SongSort! = {name: asc}): [Song!]!
          topSong(input: TopSongInput!): Song
        }

        type Song {
          name: String!
        }

        input SongSort {
          name: SortDirection
        }

        enum SortDirection {
          asc
          desc
        }

        input TopSongInput {
          thisYear: Boolean! = true
        }
      GRAPHQL

      schema = GraphQL::Schema.from_definition(
        schema_graphql,
        default_resolve: {
          "Query" => {
            "songs" => ->(obj, args, ctx) {
              sort = args[:sort]
              names = ["asc", nil].include?(sort[:name]) ? ["A", "B"] : ["B", "A"]
              names.map { |name| Struct.new(:name).new(name) }
            },
            "topSong" => ->(obj, args, ctx) {
              args[:input][:this_year] ? OpenStruct.new(name: "Hey Ya!") : OpenStruct.new(name: "Here Comes the Sun")
            }
          }
        }
      )

      result = schema.execute("query($sort: SongSort) { songs(sort: $sort) { name } }", variables: {})
      expected_result = {"data" => {"songs" => [{"name" => "A"},{"name" => "B"}]}}
      assert_graphql_equal expected_result, result

      result = schema.execute("query($sort: SongSort) { songs(sort: $sort) { name } }", variables: { sort: { name: "desc" } })
      expected_result = {"data" => {"songs" => [{"name" => "B"},{"name" => "A"}]}}
      assert_graphql_equal expected_result, result

      result = schema.execute("query($sort: SongSort) { songs(sort: $sort) { name } }", variables: { sort: nil })
      expected_result = {"errors"=>[{"message"=>"`null` is not a valid input for `SongSort!`, please provide a value for this argument.", "locations"=>[{"line"=>1, "column"=>26}], "path"=>["songs"]}], "data" => nil}
      assert_graphql_equal expected_result, result

      result = schema.execute("{ topSong(input: {}) { name } }")
      assert_equal "Hey Ya!", result["data"]["topSong"]["name"]

      result = schema.execute("{ topSong(input: { thisYear: false }) { name } }")
      assert_equal "Here Comes the Sun", result["data"]["topSong"]["name"]

      result = schema.execute("{ topSong(input: { thisYear: null }) { name } }")
      assert_equal ["Argument 'thisYear' on InputObject 'TopSongInput' has an invalid value (null). Expected type 'Boolean!'."], result["errors"].map { |err| err["message"] }
    end
  end
end
