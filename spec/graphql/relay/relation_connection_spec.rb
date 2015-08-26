require 'spec_helper'

describe GraphQL::Relay::RelationConnection do
  def get_names(result)
    ships = result["data"]["empire"]["bases"]["edges"]
    names = ships.map { |e| e["node"]["name"] }
  end

  def get_page_info(result)
    result["data"]["empire"]["bases"]["pageInfo"]
  end

  def get_last_cursor(result)
    result["data"]["empire"]["bases"]["edges"].last["cursor"]
  end

  describe "results" do
    let(:query_string) {%|
      query getShips($first: Int, $after: String, $last: Int, $before: String, $order: String, $nameIncludes: String){
        empire {
          bases(first: $first, after: $after, last: $last, before: $before, order: $order, nameIncludes: $nameIncludes) {
            ... basesConnection
            pageInfo {
              hasNextPage
            }
          }
        }
      }

      fragment basesConnection on BaseConnection {
        totalCount,
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

    it 'provides custom fileds on the connection type' do
      result = query(query_string, "first" => 2)
      assert_equal(
        Base.where(faction_id: 2).count,
        result["data"]["empire"]["bases"]["totalCount"]
      )
    end

    it 'slices the result' do
      result = query(query_string, "first" => 2)
      assert_equal(["Death Star", "Shield Generator"], get_names(result))

      # After the last result, find the next 2:
      last_cursor = get_last_cursor(result)

      result = query(query_string, "after" => last_cursor, "first" => 2)
      assert_equal(["Headquarters"], get_names(result))

      result = query(query_string, "before" => last_cursor, "last" => 2)
      assert_equal(["Death Star"], get_names(result))
    end

    it 'paginates with order' do
      result = query(query_string, "first" => 2, "order" => "name")
      assert_equal(["Death Star", "Headquarters"], get_names(result))

      # After the last result, find the next 2:
      last_cursor = get_last_cursor(result)

      result = query(query_string, "after" => last_cursor, "first" => 2, "order" => "name")
      assert_equal(["Shield Generator"], get_names(result))
    end

    it 'paginates with reverse order' do
      result = query(query_string, "first" => 2, "order" => "-name")
      assert_equal(["Shield Generator", "Headquarters"], get_names(result))
    end

    it 'paginates with order' do
      result = query(query_string, "first" => 2, "order" => "name")
      assert_equal(["Death Star", "Headquarters"], get_names(result))

      # After the last result, find the next 2:
      last_cursor = result["data"]["empire"]["bases"]["edges"].last["cursor"]

      result = query(query_string, "after" => last_cursor, "first" => 2, "order" => "name")
      assert_equal(["Shield Generator"], get_names(result))
    end

    it "applies custom arguments" do
      result = query(query_string, "first" => 1, "nameIncludes" => "ea")
      assert_equal(["Death Star"], get_names(result))

      after = get_last_cursor(result)

      result = query(query_string, "first" => 2, "nameIncludes" => "ea", "after" => after )
      assert_equal(["Headquarters"], get_names(result))
      before = get_last_cursor(result)

      result = query(query_string, "last" => 1, "nameIncludes" => "ea", "before" => before)
      assert_equal(["Death Star"], get_names(result))
    end
  end
end
