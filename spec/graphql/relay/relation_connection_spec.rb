require 'spec_helper'

describe GraphQL::Relay::RelationConnection do
  def get_names(result)
    ships = result["data"]["empire"]["bases"]["edges"]
    names = ships.map { |e| e["node"]["name"] }
  end

  def get_page_info(result)
    result["data"]["empire"]["bases"]["pageInfo"]
  end

  describe "results" do
    let(:query_string) {%|
      query getShips($first: Int, $after: String, $last: Int, $before: String, $order: String){
        empire {
          bases(first: $first, after: $after, last: $last, before: $before, order: $order) {
            ... basesConnection
            pageInfo {
              hasNextPage
            }
          }
        }
      }

      fragment basesConnection on BaseConnection {
        edges {
          cursor
          node {
            name
          }
        }
      }
    |}
    it 'limits the result' do
      result = query(query_string, "first" => 2)
      assert_equal(2, get_names(result).length)

      result = query(query_string, "first" => 3)
      assert_equal(3, get_names(result).length)
    end

    it 'provides pageInfo' do
      result = query(query_string, "first" => 2)
      assert_equal(true, get_page_info(result)["hasNextPage"])

      result = query(query_string, "first" => 100)
      assert_equal(false, get_page_info(result)["hasNextPage"])
    end

    it 'slices the result' do
      result = query(query_string, "first" => 2)
      assert_equal(["Death Star", "Shield Generator"], get_names(result))

      # After the last result, find the next 2:
      last_cursor = result["data"]["empire"]["bases"]["edges"].last["cursor"]

      result = query(query_string, "after" => last_cursor, "first" => 2)
      assert_equal(["Headquarters"], get_names(result))

      result = query(query_string, "before" => last_cursor, "last" => 2)
      assert_equal(["Death Star"], get_names(result))
    end

    it 'paginates with order' do
      result = query(query_string, "first" => 2, "order" => "name")
      assert_equal(["Death Star", "Headquarters"], get_names(result))

      # After the last result, find the next 2:
      last_cursor = result["data"]["empire"]["bases"]["edges"].last["cursor"]

      result = query(query_string, "after" => last_cursor, "first" => 2, "order" => "name")
      assert_equal(["Shield Generator"], get_names(result))
    end

    it 'paginates with reverse order' do
      result = query(query_string, "first" => 2, "order" => "-name")
      assert_equal(["Shield Generator", "Headquarters"], get_names(result))
    end
  end
end
