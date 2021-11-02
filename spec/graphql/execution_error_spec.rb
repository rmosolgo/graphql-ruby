# frozen_string_literal: true
require "spec_helper"

describe GraphQL::ExecutionError do
  let(:result) { Dummy::Schema.execute(query_string) }
  describe "when returned from a field" do
    let(:query_string) {%|
  {
    cheese(id: 1) {
      id
      error1: similarCheese(source: [YAK]) {
        ... similarCheeseFields
      }
      error2: similarCheese(source: [YAK]) {
        ... similarCheeseFields
      }
      nonError: similarCheese(source: [SHEEP]) {
        ... similarCheeseFields
      }
      flavor
    }
    allDairy {
      ... on Cheese {
        flavor
      }
      ... on Milk {
        source
        executionError
      }
    }
    dairyErrors: allDairy(executionErrorAtIndex: 1) {
      __typename
    }
    dairy {
      milks {
        source
        executionError
        allDairy {
          __typename
          ... on Milk {
            origin
            executionError
          }
        }
      }
    }
    executionError
    valueWithExecutionError
  }

  fragment similarCheeseFields on Cheese {
    id, flavor
  }
    |}

    it "the error is inserted into the errors key and the rest of the query is fulfilled" do
      expected_result = {
        "data"=>{
          "cheese"=>{
            "id" => 1,
            "error1"=> nil,
            "error2"=> nil,
            "nonError"=> {
              "id" => 3,
              "flavor" => "Manchego",
            },
            "flavor" => "Brie",
          },
          "allDairy" => [
            { "flavor" => "Brie" },
            { "flavor" => "Gouda" },
            { "flavor" => "Manchego" },
            { "source" => "COW", "executionError" => nil }
          ],
          "dairyErrors" => [
            { "__typename" => "Cheese" },
            nil,
            { "__typename" => "Cheese" },
            { "__typename" => "Milk" }
          ],
          "dairy" => {
            "milks" => [
              {
                "source" => "COW",
                "executionError" => nil,
                "allDairy" => [
                  { "__typename" => "Cheese" },
                  { "__typename" => "Cheese" },
                  { "__typename" => "Cheese" },
                  { "__typename" => "Milk", "origin" => "Antiquity", "executionError" => nil }
                ]
              }
            ]
          },
          "executionError" => nil,
          "valueWithExecutionError" => 0
        },
        "errors"=>[
          {
            "message"=>"There was an execution error",
            "locations"=>[{"line"=>41, "column"=>5}],
            "path"=>["executionError"]
          },
          {
            "message"=>"Could not fetch latest value",
            "locations"=>[{"line"=>42, "column"=>5}],
            "path"=>["valueWithExecutionError"]
          },
          {
            "message"=>"missing dairy",
            "locations"=>[{"line"=>25, "column"=>5}],
            "path"=>["dairyErrors", 1]
          },
          {
            "message"=>"There was an execution error",
            "locations"=>[{"line"=>31, "column"=>9}],
            "path"=>["dairy", "milks", 0, "executionError"]
          },
          {
            "message"=>"There was an execution error",
            "locations"=>[{"line"=>22, "column"=>9}],
            "path"=>["allDairy", 3, "executionError"]
          },
          {
            "message"=>"There was an execution error",
            "locations"=>[{"line"=>36, "column"=>13}],
            "path"=>["dairy", "milks", 0, "allDairy", 3, "executionError"]
          },
          {
            "message"=>"No cheeses are made from Yak milk!",
            "locations"=>[{"line"=>5, "column"=>7}],
            "path"=>["cheese", "error1"]
          },
          {
            "message"=>"No cheeses are made from Yak milk!",
            "locations"=>[{"line"=>8, "column"=>7}],
            "path"=>["cheese", "error2"]
          },
        ]
      }
      assert_equal(expected_result, result.to_h)
    end
  end

  describe "named query when returned from a field" do
    let(:query_string) {%|
    query MilkQuery {
      dairy {
        milks {
          source
          executionError
          allDairy {
            __typename
            ... on Milk {
              origin
              executionError
            }
          }
        }
      }
    }
    |}
    it "the error is inserted into the errors key and the rest of the query is fulfilled" do
      expected_result = {
        "data"=>{
            "dairy" => {
              "milks" => [
                {
                  "source" => "COW",
                  "executionError" => nil,
                  "allDairy" => [
                    { "__typename" => "Cheese" },
                    { "__typename" => "Cheese" },
                    { "__typename" => "Cheese" },
                    { "__typename" => "Milk", "origin" => "Antiquity", "executionError" => nil }
                  ]
                }
              ]
            }
          },
          "errors"=>[
            {
              "message"=>"There was an execution error",
              "locations"=>[{"line"=>6, "column"=>11}],
              "path"=>["dairy", "milks", 0, "executionError"]
            },
            {
              "message"=>"There was an execution error",
              "locations"=>[{"line"=>11, "column"=>15}],
              "path"=>["dairy", "milks", 0, "allDairy", 3, "executionError"]
            }
          ]
        }
      assert_equal(expected_result, result)
    end
  end

  describe "minimal lazy non-error case" do
    let(:query_string) {%|
  {
    cheese(id: 1) {
      nonError: similarCheese(source: [SHEEP]) {
        id
      }
    }
  }
    |}

    it "does lazy non-errors right" do
      # This is extracted from the test above -- it kept breaking
      # when working on dataloader, so I isolated it to keep an eye
      # on the minimal reproduction
      expected_result = {
        "data"=>{
          "cheese"=>{
            "nonError"=> {
              "id" => 3,
            },
          },
        }
      }
      assert_equal(expected_result, result.to_h)
    end
  end

  describe "fragment query when returned from a field" do
    let(:query_string) {%|
    query MilkQuery {
      dairy {
        ...Dairy
      }
    }

    fragment Dairy on Dairy {
      milks {
        source
        executionError
        allDairy {
          __typename
          ...Milk
        }
      }
    }

    fragment Milk on Milk {
      origin
      executionError
    }
    |}
    it "the error is inserted into the errors key and the rest of the query is fulfilled" do
      expected_result = {
        "data"=>{
            "dairy" => {
              "milks" => [
                {
                  "source" => "COW",
                  "executionError" => nil,
                  "allDairy" => [
                    { "__typename" => "Cheese" },
                    { "__typename" => "Cheese" },
                    { "__typename" => "Cheese" },
                    { "__typename" => "Milk", "origin" => "Antiquity", "executionError" => nil }
                  ]
                }
              ]
            }
          },
          "errors"=>[
            {
              "message"=>"There was an execution error",
              "locations"=>[{"line"=>11, "column"=>9}],
              "path"=>["dairy", "milks", 0, "executionError"]
            },
            {
              "message"=>"There was an execution error",
              "locations"=>[{"line"=>21, "column"=>7}],
              "path"=>["dairy", "milks", 0, "allDairy", 3, "executionError"]
            }
          ]
        }
      assert_equal(expected_result, result)
    end
  end

  describe "options in ExecutionError" do
    let(:query_string) {%|
    {
      executionErrorWithOptions
    }
    |}
    it "the error is inserted into the errors key and the rest of the query is fulfilled" do
      expected_result = {
        "data"=>{"executionErrorWithOptions"=>nil},
        "errors"=>
            [{"message"=>"Permission Denied!",
              "locations"=>[{"line"=>3, "column"=>7}],
              "path"=>["executionErrorWithOptions"],
              "code"=>"permission_denied"}]
      }
      assert_equal(expected_result, result)
    end
  end

  describe "extensions in ExecutionError" do
    let(:query_string) {%|
    {
      executionErrorWithExtensions
    }
    |}
    it "the error is inserted into the errors key with custom data set in `extensions`" do
      expected_result = {
        "data"=>{"executionErrorWithExtensions"=>nil},
        "errors"=>
            [{"message"=>"Permission Denied!",
              "locations"=>[{"line"=>3, "column"=>7}],
              "path"=>["executionErrorWithExtensions"],
              "extensions"=>{"code"=>"permission_denied"}}]
      }
      assert_equal(expected_result, result)
    end
  end

  describe "more than one ExecutionError" do
    let(:query_string) { %|{ multipleErrorsOnNonNullableField} |}
    it "the errors are inserted into the errors key and the data is nil even for a NonNullable field" do
      expected_result = {
        "data"=>nil,
        "errors"=>
          [{"message"=>"This is an error message for some error.",
            "locations"=>[{"line"=>1, "column"=>3}],
            "path"=>["multipleErrorsOnNonNullableField"]},
           {"message"=>"This is another error message for a different error.",
            "locations"=>[{"line"=>1, "column"=>3}],
            "path"=>["multipleErrorsOnNonNullableField"]}],
      }
      assert_equal(expected_result, result)
    end

    describe "more than one ExecutionError on a field defined to return a list" do
      let(:query_string) { %|{ multipleErrorsOnNonNullableListField} |}
      it "the errors are inserted into the errors key and the data is nil even for a NonNullable field" do
        expected_result = {
          "data"=>{"multipleErrorsOnNonNullableListField"=>[nil, nil]},
          "errors"=>
            [{"message"=>"The first error message for a field defined to return a list of strings.",
              "locations"=>[{"line"=>1, "column"=>3}],
              "path"=>["multipleErrorsOnNonNullableListField", 0]},
             {"message"=>"The second error message for a field defined to return a list of strings.",
              "locations"=>[{"line"=>1, "column"=>3}],
              "path"=>["multipleErrorsOnNonNullableListField", 1]}],
        }
        assert_equal(expected_result, result)
      end
    end
  end

  it "supports arrays containing only execution errors for list fields" do
    schema = GraphQL::Schema.from_definition <<-GRAPHQL
      type Query {
        testArray: [String]!
      }
    GRAPHQL

    root_value = OpenStruct.new(testArray: [GraphQL::ExecutionError.new("boom!"), GraphQL::ExecutionError.new("bang!"), "OK"])
    result = schema.execute("{ testArray }", root_value: root_value)
    assert_equal({ "testArray" => [nil, nil, "OK"]}, result["data"])
    expected_errors = [
      {
        "message"=>"boom!",
        "locations"=>[{"line"=>1, "column"=>3}],
        "path"=>["testArray", 0]
      },
      {
        "message"=>"bang!",
        "locations"=>[{"line"=>1, "column"=>3}],
        "path"=>["testArray", 1]
      }
    ]
    assert_equal(expected_errors, result["errors"])

    root_value_errors_only = OpenStruct.new(testArray: [GraphQL::ExecutionError.new("zing!"), GraphQL::ExecutionError.new("fizz!")])
    result = schema.execute("{ testArray }", root_value: root_value_errors_only)
    assert_equal({ "testArray" => [nil, nil] }, result["data"])
    expected_errors = [
      {
        "message"=>"zing!",
        "locations"=>[{"line"=>1, "column"=>3}],
        "path"=>["testArray", 0]
      },
      {
        "message"=>"fizz!",
        "locations"=>[{"line"=>1, "column"=>3}],
        "path"=>["testArray", 1]
      }
    ]
    assert_equal(expected_errors, result["errors"])
  end
end
