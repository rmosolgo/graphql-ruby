require 'spec_helper'

describe GraphQL::Relay::ArrayConnection do
  describe "#first" do
    let(:query_string) {%|
      query getShips($first: Int, $after: String, $last: Int, $before: String){
        rebels {
          ships(first: $first, after: $after, last: $last, before: $before) {
            edges {
              cursor
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
      result = query(query_string, "first" => 2)
      number_of_ships = result["data"]["rebels"]["ships"]["edges"].length
      assert_equal(2, number_of_ships)
      assert_equal(true, result["data"]["rebels"]["ships"]["pageInfo"]["hasNextPage"])

      result = query(query_string, "first" => 3)
      number_of_ships = result["data"]["rebels"]["ships"]["edges"].length
      assert_equal(3, number_of_ships)
    end

    it 'provides pageInfo' do
      result = query(query_string, "first" => 2)
      assert_equal(true, result["data"]["rebels"]["ships"]["pageInfo"]["hasNextPage"])

      result = query(query_string, "first" => 100)
      assert_equal(false, result["data"]["rebels"]["ships"]["pageInfo"]["hasNextPage"])
    end

    it 'slices the result' do
      result = query(query_string, "first" => 3)
      ships = result["data"]["rebels"]["ships"]["edges"]
      names = ships.map { |e| e["node"]["name"] }
      assert_equal(["X-Wing", "Y-Wing", "A-Wing"], names)

      # After the last result, find the next 2:
      last_cursor = ships.last["cursor"]

      result = query(query_string, "after" => last_cursor, "first" => 2)
      ships = result["data"]["rebels"]["ships"]["edges"]
      names = ships.map { |e| e["node"]["name"] }
      assert_equal(["Millenium Falcon", "Home One"], names)

      result = query(query_string, "before" => last_cursor, "last" => 2)
      ships = result["data"]["rebels"]["ships"]["edges"]
      names = ships.map { |e| e["node"]["name"] }
      assert_equal(["X-Wing", "Y-Wing"], names)

    end
  end
end
