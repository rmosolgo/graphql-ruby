require 'spec_helper'

describe GraphQL::Relay::ArrayConnection do
  describe "#first" do
    let(:query_string) {%|
      query getShips($num: Int){
        rebels {
          ships(first: $num) {
            edges {
              node {
                name
              }
            }
            pageInfo {
              hasNextPage
            }
          }
        }
      }
    |}
    it 'limits the result' do
      result = query(query_string, "num" => 2)
      number_of_ships = result["data"]["rebels"]["ships"]["edges"].length
      assert_equal(2, number_of_ships)
      assert_equal(true, result["data"]["rebels"]["ships"]["pageInfo"]["hasNextPage"])

      result = query(query_string, "num" => 3)
      number_of_ships = result["data"]["rebels"]["ships"]["edges"].length
      assert_equal(3, number_of_ships)
    end

    it 'provides pageInfo' do
      result = query(query_string, "num" => 2)
      assert_equal(true, result["data"]["rebels"]["ships"]["pageInfo"]["hasNextPage"])

      result = query(query_string, "num" => 100)
      assert_equal(false, result["data"]["rebels"]["ships"]["pageInfo"]["hasNextPage"])
    end
  end
end
