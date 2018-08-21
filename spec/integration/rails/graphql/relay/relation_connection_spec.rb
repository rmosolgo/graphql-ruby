# frozen_string_literal: true
require 'spec_helper'

describe GraphQL::Relay::RelationConnection do
  def get_names(result)
    ships = result["data"]["empire"]["bases"]["edges"]
    ships.map { |e| e["node"]["name"] }
  end

  def get_page_info(result)
    result["data"]["empire"]["bases"]["pageInfo"]
  end

  def get_first_cursor(result)
    result["data"]["empire"]["bases"]["edges"].first["cursor"]
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
          hasPreviousPage
          startCursor
          endCursor
        }
      }
    |}

    it 'limits the result' do
      result = star_wars_query(query_string, "first" => 2)
      assert_equal(2, get_names(result).length)
      assert_equal(true, get_page_info(result)["hasNextPage"])
      assert_equal(false, get_page_info(result)["hasPreviousPage"])
      assert_equal("MQ==", get_page_info(result)["startCursor"])
      assert_equal("Mg==", get_page_info(result)["endCursor"])
      assert_equal("MQ==", get_first_cursor(result))
      assert_equal("Mg==", get_last_cursor(result))

      result = star_wars_query(query_string, "first" => 3)
      assert_equal(3, get_names(result).length)
      assert_equal(false, get_page_info(result)["hasNextPage"])
      assert_equal(false, get_page_info(result)["hasPreviousPage"])
      assert_equal("MQ==", get_page_info(result)["startCursor"])
      assert_equal("Mw==", get_page_info(result)["endCursor"])
      assert_equal("MQ==", get_first_cursor(result))
      assert_equal("Mw==", get_last_cursor(result))
    end

    it 'provides custom fields on the connection type' do
      result = star_wars_query(query_string, "first" => 2)
      assert_equal(
        StarWars::Base.where(faction_id: 2).count,
        result["data"]["empire"]["bases"]["totalCount"]
      )
    end

    it "makes one sql query for items and another for count" do
      query_str = <<-GRAPHQL
      {
        empire {
          bases(first: 2) {
            totalCount
            edges {
              cursor
              node {
                name
              }
            }
          }
        }
      }
      GRAPHQL
      io = StringIO.new
      begin
        prev_logger = ActiveRecord::Base.logger
        ActiveRecord::Base.logger = Logger.new(io)
        result = star_wars_query(query_str, "first" => 2)
      ensure
        ActiveRecord::Base.logger = prev_logger
      end
      assert_equal 2, io.string.scan("\n").count, "Two log entries"
      assert_equal 3, result["data"]["empire"]["bases"]["totalCount"]
      assert_equal 2, result["data"]["empire"]["bases"]["edges"].size
    end

    it "provides bidirectional_pagination" do
      result = star_wars_query(query_string, "first" => 1)
      last_cursor = get_last_cursor(result)

      result = star_wars_query(query_string, "first" => 1, "after" => last_cursor)
      assert_equal true, get_page_info(result)["hasNextPage"]
      assert_equal false, get_page_info(result)["hasPreviousPage"]

      result = with_bidirectional_pagination {
        star_wars_query(query_string, "first" => 1, "after" => last_cursor)
      }
      assert_equal true, get_page_info(result)["hasNextPage"]
      assert_equal true, get_page_info(result)["hasPreviousPage"]

      last_cursor = get_last_cursor(result)
      result = with_bidirectional_pagination {
        star_wars_query(query_string, "last" => 1, "before" => last_cursor)
      }
      assert_equal true, get_page_info(result)["hasNextPage"]
      assert_equal false, get_page_info(result)["hasPreviousPage"]

      result = star_wars_query(query_string, "first" => 100)
      last_cursor = get_last_cursor(result)

      result = star_wars_query(query_string, "last" => 1, "before" => last_cursor)
      assert_equal false, get_page_info(result)["hasNextPage"]
      assert_equal true, get_page_info(result)["hasPreviousPage"]

      result = with_bidirectional_pagination {
        star_wars_query(query_string, "last" => 1, "before" => last_cursor)
      }
      assert_equal true, get_page_info(result)["hasNextPage"]
      assert_equal true, get_page_info(result)["hasPreviousPage"]
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

      result = star_wars_query(query_string, "last" => 2)
      assert_equal(["Shield Generator", "Headquarters"], get_names(result))

      result = star_wars_query(query_string, "last" => 10)
      assert_equal(["Death Star", "Shield Generator", "Headquarters"], get_names(result))
      assert_equal(false, result["data"]["empire"]["bases"]["pageInfo"]["hasNextPage"])
      assert_equal(false, result["data"]["empire"]["bases"]["pageInfo"]["hasPreviousPage"])
    end

    it 'works with before and after specified together' do
      result = star_wars_query(query_string, "first" => 2)
      assert_equal(["Death Star", "Shield Generator"], get_names(result))

      first_cursor = get_last_cursor(result)

      # There is no records between before and after if they point to the same cursor
      result = star_wars_query(query_string, "before" => first_cursor, "after" => first_cursor, "last" => 2)
      assert_equal([], get_names(result))

      result = star_wars_query(query_string, "after" => first_cursor, "first" => 2)
      assert_equal(["Headquarters"], get_names(result))

      second_cursor = get_last_cursor(result)

      result = star_wars_query(query_string, "after" => first_cursor, "before" => second_cursor, "first" => 3)
      assert_equal([], get_names(result))
    end

    it 'handles cursors above the bounds of the array' do
      overreaching_cursor = Base64.strict_encode64("100")
      result = star_wars_query(query_string, "after" => overreaching_cursor, "first" => 2)
      assert_equal([], get_names(result))
    end

    it 'handles cursors below the bounds of the array' do
      underreaching_cursor = Base64.strict_encode64("1")
      result = star_wars_query(query_string, "before" => underreaching_cursor, "first" => 2)
      assert_equal([], get_names(result))
    end


    it 'handles grouped connections with only last argument' do
      grouped_conn_query = <<-GRAPHQL
      query {
        newestBasesGroupedByFaction(last: 2) {
          edges {
            node {
              name
            }
          }
        }
      }
      GRAPHQL

      result = star_wars_query(grouped_conn_query)
      names = result['data']['newestBasesGroupedByFaction']['edges'].map { |edge| edge['node']['name'] }
      assert_equal(['Headquarters', 'Secret Hideout'], names)
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

    describe "applying max_page_size" do
      let(:query_string) {%|
        query getBases($first: Int, $after: String, $last: Int, $before: String){
          empire {
            bases: basesWithMaxLimitRelation(first: $first, after: $after, last: $last, before: $before) {
              ... basesConnection
            }
          }
        }

        fragment basesConnection on BaseConnection {
          edges {
            cursor
            node {
              name
            }
          },
          pageInfo {
            hasNextPage
            hasPreviousPage
            startCursor
            endCursor
          }
        }
      |}

      it "applies to queries by `first`" do
        result = star_wars_query(query_string, "first" => 100)
        assert_equal(2, result["data"]["empire"]["bases"]["edges"].size)
        assert_equal(true, result["data"]["empire"]["bases"]["pageInfo"]["hasNextPage"])

        # Max page size is applied _without_ `first`, also
        result = star_wars_query(query_string)
        assert_equal(2, result["data"]["empire"]["bases"]["edges"].size)
        assert_equal(false, result["data"]["empire"]["bases"]["pageInfo"]["hasNextPage"], "hasNextPage is false when first is not specified")
      end

      it "applies to queries by `last`" do
        second_to_last_two_names = ["Death Star", "Shield Generator"]
        first_and_second_names = ["Yavin", "Echo Base"]

        last_cursor = "Ng=="
        result = star_wars_query(query_string, "last" => 100, "before" => last_cursor)
        assert_equal(second_to_last_two_names, get_names(result))
        assert_equal(true, result["data"]["empire"]["bases"]["pageInfo"]["hasPreviousPage"])

        result = star_wars_query(query_string, "before" => last_cursor)
        assert_equal(first_and_second_names, get_names(result))
        assert_equal(false, result["data"]["empire"]["bases"]["pageInfo"]["hasPreviousPage"], "hasPreviousPage is false when last is not specified")

        third_cursor = "Mw=="
        result = star_wars_query(query_string, "last" => 100, "before" => third_cursor)
        assert_equal(first_and_second_names, get_names(result))

        result = star_wars_query(query_string, "before" => third_cursor)
        assert_equal(first_and_second_names, get_names(result))
      end
    end

    describe "applying default_max_page_size" do
      let(:query_string) {%|
        query getBases($first: Int, $after: String, $last: Int, $before: String){
          empire {
            bases: basesWithDefaultMaxLimitRelation(first: $first, after: $after, last: $last, before: $before) {
              ... basesConnection
            }
          }
        }

        fragment basesConnection on BaseConnection {
          edges {
            cursor
            node {
              name
            }
          },
          pageInfo {
            hasNextPage
            hasPreviousPage
            startCursor
            endCursor
          }
        }
        |}

      it "applies to queries by `first`" do
        result = star_wars_query(query_string, "first" => 100)
        assert_equal(3, result["data"]["empire"]["bases"]["edges"].size)
        assert_equal(true, result["data"]["empire"]["bases"]["pageInfo"]["hasNextPage"])

        # Max page size is applied _without_ `first`, also
        result = star_wars_query(query_string)
        assert_equal(3, result["data"]["empire"]["bases"]["edges"].size)
        assert_equal(false, result["data"]["empire"]["bases"]["pageInfo"]["hasNextPage"], "hasNextPage is false when first is not specified")
      end

      it "applies to queries by `last`" do
        second_to_last_three_names = ["Secret Hideout", "Death Star", "Shield Generator"]
        first_second_and_third_names = ["Yavin", "Echo Base", "Secret Hideout"]

        last_cursor = "Ng=="
        result = star_wars_query(query_string, "last" => 100, "before" => last_cursor)
        assert_equal(second_to_last_three_names, get_names(result))
        assert_equal(true, result["data"]["empire"]["bases"]["pageInfo"]["hasPreviousPage"])

        result = star_wars_query(query_string, "before" => last_cursor)
        assert_equal(first_second_and_third_names, get_names(result))
        assert_equal(false, result["data"]["empire"]["bases"]["pageInfo"]["hasPreviousPage"], "hasPreviousPage is false when last is not specified")

        fourth_cursor = "NA=="
        result = star_wars_query(query_string, "last" => 100, "before" => fourth_cursor)
        assert_equal(first_second_and_third_names, get_names(result))

        result = star_wars_query(query_string, "before" => fourth_cursor)
        assert_equal(first_second_and_third_names, get_names(result))
      end
    end
  end

  describe "applying a max_page_size bigger than the results" do
    let(:query_string) {%|
      query getBases($first: Int, $after: String, $last: Int, $before: String){
        empire {
          bases: basesWithLargeMaxLimitRelation(first: $first, after: $after, last: $last, before: $before) {
            ... basesConnection
          }
        }
      }

      fragment basesConnection on BaseConnection {
        edges {
          cursor
          node {
            name
          }
        },
        pageInfo {
          hasNextPage
          hasPreviousPage
          startCursor
          endCursor
        }
      }
      |}

    it "applies to queries by `first`" do
      result = star_wars_query(query_string, "first" => 100)
      assert_equal(6, result["data"]["empire"]["bases"]["edges"].size)
      assert_equal(false, result["data"]["empire"]["bases"]["pageInfo"]["hasNextPage"])

      # Max page size is applied _without_ `first`, also
      result = star_wars_query(query_string)
      assert_equal(6, result["data"]["empire"]["bases"]["edges"].size)
      assert_equal(false, result["data"]["empire"]["bases"]["pageInfo"]["hasNextPage"], "hasNextPage is false when first is not specified")
    end

    it "applies to queries by `last`" do
      all_names = ["Yavin", "Echo Base", "Secret Hideout", "Death Star", "Shield Generator", "Headquarters"]

      last_cursor = "Ng=="
      result = star_wars_query(query_string, "last" => 100, "before" => last_cursor)
      assert_equal(all_names[0..4], get_names(result))
      assert_equal(false, result["data"]["empire"]["bases"]["pageInfo"]["hasPreviousPage"])

      result = star_wars_query(query_string, "last" => 100)
      assert_equal(all_names, get_names(result))
      assert_equal(false, result["data"]["empire"]["bases"]["pageInfo"]["hasPreviousPage"])

      result = star_wars_query(query_string, "before" => last_cursor)
      assert_equal(all_names[0..4], get_names(result))
      assert_equal(false, result["data"]["empire"]["bases"]["pageInfo"]["hasPreviousPage"], "hasPreviousPage is false when last is not specified")

      fourth_cursor = "NA=="
      result = star_wars_query(query_string, "last" => 100, "before" => fourth_cursor)
      assert_equal(all_names[0..2], get_names(result))

      result = star_wars_query(query_string, "before" => fourth_cursor)
      assert_equal(all_names[0..2], get_names(result))
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
      bases.map { |b| b["node"]["name"] }
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
      ships.map { |e| e["node"]["name"] }
    end

    def get_page_info(result)
      result["data"]["empire"]["basesAsSequelDataset"]["pageInfo"]
    end

    def get_first_cursor(result)
      result["data"]["empire"]["basesAsSequelDataset"]["edges"].first["cursor"]
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
            hasPreviousPage
            startCursor
            endCursor
          }
        }
      |}

      it 'limits the result' do
        result = star_wars_query(query_string, "first" => 2)
        assert_equal(2, get_names(result).length)
        assert_equal(true, get_page_info(result)["hasNextPage"])
        assert_equal(false, get_page_info(result)["hasPreviousPage"])
        assert_equal("MQ==", get_page_info(result)["startCursor"])
        assert_equal("Mg==", get_page_info(result)["endCursor"])
        assert_equal("MQ==", get_first_cursor(result))
        assert_equal("Mg==", get_last_cursor(result))

        result = star_wars_query(query_string, "first" => 3)
        assert_equal(3, get_names(result).length)
        assert_equal(false, get_page_info(result)["hasNextPage"])
        assert_equal(false, get_page_info(result)["hasPreviousPage"])
        assert_equal("MQ==", get_page_info(result)["startCursor"])
        assert_equal("Mw==", get_page_info(result)["endCursor"])
        assert_equal("MQ==", get_first_cursor(result))
        assert_equal("Mw==", get_last_cursor(result))
      end

      it 'provides custom fields on the connection type' do
        result = star_wars_query(query_string, "first" => 2)
        assert_equal(
          StarWars::Base.where(faction_id: 2).count,
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

      it 'handles cursors above the bounds of the array' do
        overreaching_cursor = Base64.strict_encode64("100")
        result = star_wars_query(query_string, "after" => overreaching_cursor, "first" => 2)
        assert_equal([], get_names(result))
      end

      it 'handles cursors below the bounds of the array' do
        underreaching_cursor = Base64.strict_encode64("1")
        result = star_wars_query(query_string, "before" => underreaching_cursor, "first" => 2)
        assert_equal([], get_names(result))
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

      it "makes one sql query for items and another for count" do
        query_str = <<-GRAPHQL
        {
          empire {
            basesAsSequelDataset(first: 2) {
              totalCount
              edges {
                cursor
                node {
                  name
                }
              }
            }
          }
        }
        GRAPHQL
        result = nil
        io = StringIO.new
        begin
          StarWars::DB.loggers << Logger.new(io)
          result = star_wars_query(query_str, "first" => 2)
        ensure
          StarWars::DB.loggers.pop
        end
        assert_equal 2, io.string.scan("SELECT").count
        assert_equal 3, result["data"]["empire"]["basesAsSequelDataset"]["totalCount"]
        assert_equal 2, result["data"]["empire"]["basesAsSequelDataset"]["edges"].size
      end
    end
  end

  describe "#cursor_from_node" do
    let(:connection) { GraphQL::Relay::RelationConnection.new(StarWars::Base.where(faction_id: 1), {}) }

    it "returns the cursor for a node in the connection" do
      assert_equal "MQ==", connection.cursor_from_node(StarWars::Base.all[0])
      assert_equal "Mg==", connection.cursor_from_node(StarWars::Base.all[1])
    end

    it "raises when the node isn't found" do
      err = assert_raises(RuntimeError) {
        connection.cursor_from_node(:not_found)
      }
      assert_includes err.message, "item not found"
    end
  end

  it "is chosen for a relation" do
    relation = StarWars::Base.where(faction_id: 1)
    assert relation.is_a?(ActiveRecord::Relation)
    connection = GraphQL::Relay::BaseConnection.connection_for_nodes(relation)
    assert_equal GraphQL::Relay::RelationConnection, connection
  end

  describe "for an ActiveRecord::Relation" do
    describe "#has_next_page" do
      it "handles joined, aliased relations" do
        relation = StarWars::Base.select("id AS crazy_id")
        connection = GraphQL::Relay::RelationConnection.new(relation, { first: 1 })
        assert connection.has_next_page
      end
    end

    describe "#edge_nodes" do
      it "returns the nodes for the current page" do
        # Offset
        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.offset(2), {})
        assert_equal [StarWars::Base.find(3), StarWars::Base.find(4), StarWars::Base.find(5), StarWars::Base.find(6)], connection.edge_nodes,

        cursor1 = connection.cursor_from_node(StarWars::Base.find(3))
        cursor2 = connection.cursor_from_node(StarWars::Base.find(4))
        cursor3 = connection.cursor_from_node(StarWars::Base.find(5))
        cursor4 = connection.cursor_from_node(StarWars::Base.find(6))

        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.offset(2), { first: 3 })
        assert_equal [StarWars::Base.find(3), StarWars::Base.find(4), StarWars::Base.find(5)], connection.edge_nodes

        assert_equal cursor1, connection.cursor_from_node(StarWars::Base.find(3))
        assert_equal cursor2, connection.cursor_from_node(StarWars::Base.find(4))
        assert_equal cursor3, connection.cursor_from_node(StarWars::Base.find(5))

        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.offset(2), { last: 3 })
        assert_equal [StarWars::Base.find(4), StarWars::Base.find(5), StarWars::Base.find(6)], connection.edge_nodes

        assert_equal cursor2, connection.cursor_from_node(StarWars::Base.find(4))
        assert_equal cursor3, connection.cursor_from_node(StarWars::Base.find(5))
        assert_equal cursor4, connection.cursor_from_node(StarWars::Base.find(6))

        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.offset(2), { last: 2 })
        assert_equal [StarWars::Base.find(5), StarWars::Base.find(6)], connection.edge_nodes

        assert_equal cursor3, connection.cursor_from_node(StarWars::Base.find(5))
        assert_equal cursor4, connection.cursor_from_node(StarWars::Base.find(6))

        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.offset(2), { first: 3, last: 1 })
        assert_equal [StarWars::Base.find(5)], connection.edge_nodes

        assert_equal cursor3, connection.cursor_from_node(StarWars::Base.find(5))

        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.offset(2), { first: 2, last: 1 })
        assert_equal [StarWars::Base.find(4)], connection.edge_nodes

        assert_equal cursor2, connection.cursor_from_node(StarWars::Base.find(4))

        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.offset(2), { after: cursor1 })
        assert_equal [StarWars::Base.find(4), StarWars::Base.find(5), StarWars::Base.find(6)], connection.edge_nodes

        assert_equal cursor2, connection.cursor_from_node(StarWars::Base.find(4))
        assert_equal cursor3, connection.cursor_from_node(StarWars::Base.find(5))
        assert_equal cursor4, connection.cursor_from_node(StarWars::Base.find(6))

        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.offset(2), { after: cursor1, before: cursor1 })
        assert_equal [], connection.edge_nodes

        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.offset(2), { after: cursor1, before: cursor3 })
        assert_equal [StarWars::Base.find(4)], connection.edge_nodes

        assert_equal cursor2, connection.cursor_from_node(StarWars::Base.find(4))

        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.offset(2), { after: cursor1, before: cursor4 })
        assert_equal [StarWars::Base.find(4), StarWars::Base.find(5)], connection.edge_nodes

        assert_equal cursor2, connection.cursor_from_node(StarWars::Base.find(4))
        assert_equal cursor3, connection.cursor_from_node(StarWars::Base.find(5))


        # Limit
        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.limit(5), {})
        assert_equal [StarWars::Base.find(1), StarWars::Base.find(2), StarWars::Base.find(3), StarWars::Base.find(4), StarWars::Base.find(5)], connection.edge_nodes

        cursor1 = connection.cursor_from_node(StarWars::Base.find(1))
        cursor2 = connection.cursor_from_node(StarWars::Base.find(2))
        cursor3 = connection.cursor_from_node(StarWars::Base.find(3))
        cursor4 = connection.cursor_from_node(StarWars::Base.find(4))

        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.limit(5), { first: 2 })
        assert_equal [StarWars::Base.find(1), StarWars::Base.find(2)], connection.edge_nodes

        assert_equal cursor1, connection.cursor_from_node(StarWars::Base.find(1))
        assert_equal cursor2, connection.cursor_from_node(StarWars::Base.find(2))

        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.limit(5), { first: 2, last: 1 })
        assert_equal [StarWars::Base.find(2)], connection.edge_nodes

        assert_equal cursor2, connection.cursor_from_node(StarWars::Base.find(2))

        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.limit(5), { after: cursor2, first: 2 })
        assert_equal [StarWars::Base.find(3), StarWars::Base.find(4)], connection.edge_nodes

        assert_equal cursor3, connection.cursor_from_node(StarWars::Base.find(3))
        assert_equal cursor4, connection.cursor_from_node(StarWars::Base.find(4))

        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.limit(5), { after: cursor2, first: 2, last: 1 })
        assert_equal [StarWars::Base.find(4)], connection.edge_nodes

        assert_equal cursor4, connection.cursor_from_node(StarWars::Base.find(4))

        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.limit(5), { first: 2, last: 5 })
        assert_equal [StarWars::Base.find(1), StarWars::Base.find(2)], connection.edge_nodes

        assert_equal cursor1, connection.cursor_from_node(StarWars::Base.find(1))
        assert_equal cursor2, connection.cursor_from_node(StarWars::Base.find(2))

        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.limit(5), { first: 1, last: 5 })
        assert_equal [StarWars::Base.find(1)], connection.edge_nodes

        assert_equal cursor1, connection.cursor_from_node(StarWars::Base.find(1))

        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.limit(5), { after: cursor1, before: cursor1 })
        assert_equal [], connection.edge_nodes

        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.limit(5), { after: cursor1, before: cursor3 })
        assert_equal [StarWars::Base.find(2)], connection.edge_nodes

        assert_equal cursor2, connection.cursor_from_node(StarWars::Base.find(2))

        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.limit(5), { after: cursor1, before: cursor4 })
        assert_equal [StarWars::Base.find(2), StarWars::Base.find(3)], connection.edge_nodes

        assert_equal cursor2, connection.cursor_from_node(StarWars::Base.find(2))
        assert_equal cursor3, connection.cursor_from_node(StarWars::Base.find(3))

        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.limit(5), { last: 2, before: cursor4 })
        assert_equal [StarWars::Base.find(2), StarWars::Base.find(3)], connection.edge_nodes

        assert_equal cursor2, connection.cursor_from_node(StarWars::Base.find(2))
        assert_equal cursor3, connection.cursor_from_node(StarWars::Base.find(3))


        # Limit and offset
        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.offset(2).limit(3), { first: 2 })
        assert_equal [StarWars::Base.find(3), StarWars::Base.find(4)], connection.edge_nodes

        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.offset(2).limit(3), { first: 2, last: 1 })
        assert_equal [StarWars::Base.find(4)], connection.edge_nodes

        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.offset(2).limit(3), { first: 2, last: 5 })
        assert_equal [StarWars::Base.find(3), StarWars::Base.find(4)], connection.edge_nodes

        connection = GraphQL::Relay::RelationConnection.new(StarWars::Base.offset(2).limit(3), { first: 1, last: 5 })
        assert_equal [StarWars::Base.find(3)], connection.edge_nodes

      end
    end
  end
end
