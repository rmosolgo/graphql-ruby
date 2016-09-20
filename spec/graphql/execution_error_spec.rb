require "spec_helper"

describe GraphQL::ExecutionError do
  let(:result) { DummySchema.execute(query_string) }
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
      executionError
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
            "executionError" => nil,
          },
          "errors"=>[
            {
              "message"=>"No cheeses are made from Yak milk!",
              "locations"=>[{"line"=>5, "column"=>9}],
              "path"=>["cheese", "error1"]
            },
            {
              "message"=>"No cheeses are made from Yak milk!",
              "locations"=>[{"line"=>8, "column"=>9}],
              "path"=>["cheese", "error2"]
            },
            {
              "message"=>"There was an execution error",
              "locations"=>[{"line"=>22, "column"=>11}],
              "path"=>["allDairy", 3, "executionError"]
            },
            {
              "message"=>"There was an execution error",
              "locations"=>[{"line"=>25, "column"=>7}],
              "path"=>["executionError"]
            },
          ]
        }
      assert_equal(expected_result, result)
    end
  end
end
