require 'spec_helper'

describe GraphQL::Relay::ArrayConnection do
  def get_names(result)
    ships = result["data"]["rebels"]["ships"]["edges"]
    names = ships.map { |e| e["node"]["name"] }
  end

  def get_last_cursor(result)
    result["data"]["rebels"]["ships"]["edges"].last["cursor"]
  end
  describe "results" do
    let(:query_string) {%|
      query getShips($first: Int, $after: String, $last: Int, $before: String, $nameIncludes: String){
        rebels {
          ships(first: $first, after: $after, last: $last, before: $before, nameIncludes: $nameIncludes) {
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
      result = star_wars_query(query_string, "first" => 2)
      number_of_ships = get_names(result).length
      assert_equal(2, number_of_ships)
      assert_equal(true, result["data"]["rebels"]["ships"]["pageInfo"]["hasNextPage"])

      result = star_wars_query(query_string, "first" => 3)
      number_of_ships = get_names(result).length
      assert_equal(3, number_of_ships)
    end

    it 'provides pageInfo' do
      result = star_wars_query(query_string, "first" => 2)
      assert_equal(true, result["data"]["rebels"]["ships"]["pageInfo"]["hasNextPage"])

      result = star_wars_query(query_string, "first" => 100)
      assert_equal(false, result["data"]["rebels"]["ships"]["pageInfo"]["hasNextPage"])
    end

    it 'slices the result' do
      result = star_wars_query(query_string, "first" => 1)
      assert_equal(["X-Wing"], get_names(result))

      # After the last result, find the next 2:
      last_cursor = get_last_cursor(result)

      result = star_wars_query(query_string, "after" => last_cursor, "first" => 2)
      assert_equal(["Y-Wing", "A-Wing"], get_names(result))

      # After the last result, find the next 2:
      last_cursor = get_last_cursor(result)

      result = star_wars_query(query_string, "after" => last_cursor, "first" => 2)
      assert_equal(["Millenium Falcon", "Home One"], get_names(result))

      result = star_wars_query(query_string, "before" => last_cursor, "last" => 2)
      assert_equal(["X-Wing", "Y-Wing"], get_names(result))
    end

    it 'applies custom arguments' do
      result = star_wars_query(query_string, "nameIncludes" => "Wing", "first" => 2)
      names = get_names(result)
      assert_equal(2, names.length)

      after = get_last_cursor(result)
      result = star_wars_query(query_string, "nameIncludes" => "Wing", "after" => after, "first" => 3)
      names = get_names(result)
      assert_equal(1, names.length)
    end

    it 'works without first/last/after/before' do
      result = star_wars_query(query_string)

      assert_equal(false, result["data"]["rebels"]["ships"]["pageInfo"]["hasNextPage"])
      assert_equal(5, result["data"]["rebels"]["ships"]["edges"].length)
    end
  end
end
