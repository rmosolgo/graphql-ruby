require 'spec_helper'

describe GraphQL::Relay::RelationConnection do
  def get_names(result)
    ships = result["data"]["empire"]["bases"]["edges"]
    names = ships.map { |e| e["node"]["name"] }
  end

  def get_last_cursor(result)
    result["data"]["empire"]["bases"]["edges"].last["cursor"]
  end

  describe "results" do
    let(:query_string) {%|
      query getShips($first: Int, $after: String, $last: Int, $before: String,  $nameIncludes: String){
        empire {
          bases(first: $first, after: $after, last: $last, before: $before, nameIncludes: $nameIncludes) {
            ... basesConnection
          }
        }
      }

      fragment basesConnection on BasesConnectionWithTotalCount {
        totalCount,
        edges {
          cursor
          node {
            name
          }
        },
        pageInfo {
          hasNextPage
        }
      }
    |}

    it 'limits the result' do
      result = star_wars_query(query_string, "first" => 2)
      assert_equal(2, get_names(result).length)

      result = star_wars_query(query_string, "first" => 3)
      assert_equal(3, get_names(result).length)
    end

    it 'provides custom fileds on the connection type' do
      result = star_wars_query(query_string, "first" => 2)
      assert_equal(
        Base.where(faction_id: 2).count,
        result["data"]["empire"]["bases"]["totalCount"]
      )
    end

    it 'slices the result' do
      result = star_wars_query(query_string, "first" => 2)
      assert_equal(["Death Star", "Shield Generator"], get_names(result))

      # After the last result, find the next 2:
      last_cursor = get_last_cursor(result)

      result = star_wars_query(query_string, "after" => last_cursor, "first" => 2)
      assert_equal(["Headquarters"], get_names(result))

      last_cursor = get_last_cursor(result)

      result = star_wars_query(query_string, "before" => last_cursor, "last" => 1)
      assert_equal(["Shield Generator"], get_names(result))

      result = star_wars_query(query_string, "before" => last_cursor, "last" => 2)
      assert_equal(["Death Star", "Shield Generator"], get_names(result))

      result = star_wars_query(query_string, "before" => last_cursor, "last" => 10)
      assert_equal(["Death Star", "Shield Generator"], get_names(result))

    end

    it "applies custom arguments" do
      result = star_wars_query(query_string, "first" => 1, "nameIncludes" => "ea")
      assert_equal(["Death Star"], get_names(result))

      after = get_last_cursor(result)

      result = star_wars_query(query_string, "first" => 2, "nameIncludes" => "ea", "after" => after )
      assert_equal(["Headquarters"], get_names(result))
      before = get_last_cursor(result)

      result = star_wars_query(query_string, "last" => 1, "nameIncludes" => "ea", "before" => before)
      assert_equal(["Death Star"], get_names(result))
    end

    it 'works without first/last/after/before' do
      result = star_wars_query(query_string)

      assert_equal(3, result["data"]["empire"]["bases"]["edges"].length)
    end

    it "applies the maximum limit for relation connection types" do
      limit_query_string = %|
        query getShips($first: Int){
          empire {
            basesWithMaxLimitRelation(first: $first) {
              edges {
                node {
                  name
                }
              }
            }
          }
        }
      |

      result = star_wars_query(limit_query_string, "first" => 3)
      assert_equal(2, result["data"]["empire"]["basesWithMaxLimitRelation"]["edges"].size)
    end

    it "applies the maximum limit for relation connection types" do
      limit_query_string = %|
        query getShips($first: Int){
          empire {
            basesWithMaxLimitArray(first: $first) {
              edges {
                node {
                  name
                }
              }
            }
          }
        }
      |

      result = star_wars_query(limit_query_string, "first" => 3)
      assert_equal(2, result["data"]["empire"]["basesWithMaxLimitArray"]["edges"].size)

      result = star_wars_query(limit_query_string)
      assert_equal(2, result["data"]["empire"]["basesWithMaxLimitArray"]["edges"].size, "it works without arguments")
    end
  end

  describe "without a block" do
    let(:query_string) {%|
      {
        empire {
          basesClone(first: 10) {
            edges {
              node {
                name
              }
            }
          }
        }
    }|}
    it "uses default resolve" do
      result = star_wars_query(query_string)
      bases = result["data"]["empire"]["basesClone"]["edges"]
      assert_equal(3, bases.length)
    end
  end

  describe "custom ordering" do
    let(:query_string) {%|
      query getBases {
        empire {
          basesByName(first: 30) { ... basesFields }
          bases(first: 30) { ... basesFields2 }
        }
      }
      fragment basesFields on BaseConnection {
        edges {
          node {
            name
          }
        }
      }
      fragment basesFields2 on BasesConnectionWithTotalCount {
        edges {
          node {
            name
          }
        }
      }
    |}

    def get_names(result, field_name)
      bases = result["data"]["empire"][field_name]["edges"]
      base_names = bases.map { |b| b["node"]["name"] }
    end

    it "applies the default value" do
      result = star_wars_query(query_string)

      bases_by_id   = ["Death Star", "Shield Generator", "Headquarters"]
      bases_by_name = ["Death Star", "Headquarters", "Shield Generator"]

      assert_equal(bases_by_id, get_names(result, "bases"))
      assert_equal(bases_by_name, get_names(result, "basesByName"))
    end
  end

  describe "with a Sequel::Dataset" do
    def get_names(result)
      ships = result["data"]["empire"]["basesAsSequelDataset"]["edges"]
      names = ships.map { |e| e["node"]["name"] }
    end

    def get_last_cursor(result)
      result["data"]["empire"]["basesAsSequelDataset"]["edges"].last["cursor"]
    end

    describe "results" do
      let(:query_string) {%|
        query getShips($first: Int, $after: String, $last: Int, $before: String,  $nameIncludes: String){
          empire {
            basesAsSequelDataset(first: $first, after: $after, last: $last, before: $before, nameIncludes: $nameIncludes) {
              ... basesConnection
            }
          }
        }

        fragment basesConnection on BasesConnectionWithTotalCount {
          totalCount,
          edges {
            cursor
            node {
              name
            }
          },
          pageInfo {
            hasNextPage
          }
        }
      |}

      it 'limits the result' do
        result = star_wars_query(query_string, "first" => 2)
        assert_equal(2, get_names(result).length)

        result = star_wars_query(query_string, "first" => 3)
        assert_equal(3, get_names(result).length)
      end

      it 'provides custom fileds on the connection type' do
        result = star_wars_query(query_string, "first" => 2)
        assert_equal(
          Base.where(faction_id: 2).count,
          result["data"]["empire"]["basesAsSequelDataset"]["totalCount"]
        )
      end

      it 'slices the result' do
        result = star_wars_query(query_string, "first" => 2)
        assert_equal(["Death Star", "Shield Generator"], get_names(result))

        # After the last result, find the next 2:
        last_cursor = get_last_cursor(result)

        result = star_wars_query(query_string, "after" => last_cursor, "first" => 2)
        assert_equal(["Headquarters"], get_names(result))

        last_cursor = get_last_cursor(result)

        result = star_wars_query(query_string, "before" => last_cursor, "last" => 1)
        assert_equal(["Shield Generator"], get_names(result))

        result = star_wars_query(query_string, "before" => last_cursor, "last" => 2)
        assert_equal(["Death Star", "Shield Generator"], get_names(result))

        result = star_wars_query(query_string, "before" => last_cursor, "last" => 10)
        assert_equal(["Death Star", "Shield Generator"], get_names(result))

      end

      it "applies custom arguments" do
        result = star_wars_query(query_string, "first" => 1, "nameIncludes" => "ea")
        assert_equal(["Death Star"], get_names(result))

        after = get_last_cursor(result)

        result = star_wars_query(query_string, "first" => 2, "nameIncludes" => "ea", "after" => after )
        assert_equal(["Headquarters"], get_names(result))
        before = get_last_cursor(result)

        result = star_wars_query(query_string, "last" => 1, "nameIncludes" => "ea", "before" => before)
        assert_equal(["Death Star"], get_names(result))
      end
    end
  end
end
