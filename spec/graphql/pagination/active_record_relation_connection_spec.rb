# frozen_string_literal: true
require "spec_helper"

if testing_rails?
  describe GraphQL::Pagination::ActiveRecordRelationConnection do
    class RelationConnectionWithTotalCount < GraphQL::Pagination::ActiveRecordRelationConnection
      def total_count
        if items.respond_to?(:unscope)
          items.unscope(:order).count(:all)
        else
          # rails 3
          items.count
        end
      end
    end

    let(:schema) {
      ConnectionAssertions.build_schema(
        connection_class: GraphQL::Pagination::ActiveRecordRelationConnection,
        total_count_connection_class: RelationConnectionWithTotalCount,
        get_items: -> {
          if Food.respond_to?(:scoped)
            Food.scoped.limit(limit) # Rails 3-friendly version of .all
          else
            Food.all.limit(limit)
          end
        }
      )
    }

    let(:limit) { nil }

    include ConnectionAssertions

    before do
      if Food.count == 0 # Backwards-compat version of `.none?`
        ConnectionAssertions::NAMES.each { |n| Food.create!(name: n) }
      end
    end

    it "maintains an application-provided offset" do
      results = schema.execute("{
        offsetItems(first: 3) {
          nodes { name }
          pageInfo { endCursor }
        }
      }")
      assert_equal ["Cucumber", "Dill", "Eggplant"], results["data"]["offsetItems"]["nodes"].map { |n| n["name"] }
      end_cursor = results["data"]["offsetItems"]["pageInfo"]["endCursor"]

      results = schema.execute("{
        offsetItems(first: 3, after: #{end_cursor.inspect}) {
          nodes { name }
        }
      }")
      assert_equal ["Fennel", "Ginger", "Horseradish"], results["data"]["offsetItems"]["nodes"].map { |n| n["name"] }

      results = schema.execute("{
        offsetItems(last: 2, before: #{end_cursor.inspect}) {
          nodes { name }
        }
      }")
      assert_equal ["Cucumber", "Dill"], results["data"]["offsetItems"]["nodes"].map { |n| n["name"] }
    end

    describe 'with application-provided limit, which is smaller than the max_page_size' do
      let(:limit) { 1 }

      it "maintains an application-provided limit" do
        results = schema.execute("{
          limitedItems {
            nodes { name }
          }
        }")
        assert_equal ["Avocado"], results["data"]["limitedItems"]["nodes"].map { |n| n["name"] }
      end
    end

    describe 'with application-provided limit, which is larger than the max_page_size' do
      let(:limit) { 3 }

      it "applies a field-level max-page-size configuration" do
        results = schema.execute("{
          limitedItems {
            nodes { name }
          }
        }")
        assert_equal ["Avocado", "Beet"], results["data"]["limitedItems"]["nodes"].map { |n| n["name"] }
      end
    end


    it "doesn't run pageInfo queries when not necessary" do
      results = nil
      log = with_active_record_log do
        results = schema.execute("{
          items(first: 3) {
            __typename
          }
        }")
      end
      assert_equal "ItemConnection", results["data"]["items"]["__typename"]
      assert_equal "", log, "No queries are executed when no data is requested"

      log = with_active_record_log do
        results = schema.execute("{
          items(first: 3) {
            pageInfo {
              hasNextPage
              hasPreviousPage
            }
          }
        }")
      end
      assert_equal true, results["data"]["items"]["pageInfo"]["hasNextPage"]
      assert_equal false, results["data"]["items"]["pageInfo"]["hasPreviousPage"]
      assert_equal 1, log.split("\n").size, "It runs only one query"
      assert_equal 1, log.squeeze.scan("SELECT 1 AS").size, "It's an exist query (#{log.inspect})"

      log = with_active_record_log do
        results = schema.execute("{
          items(last: 3) {
            pageInfo {
              hasNextPage
              hasPreviousPage
            }
          }
        }")
      end
      assert_equal true, results["data"]["items"]["pageInfo"]["hasPreviousPage"]
      assert_equal false, results["data"]["items"]["pageInfo"]["hasNextPage"]
      assert_equal 1, log.split("\n").size, "It runs only one query"
      assert_equal 1, log.scan("COUNT(").size, "It's a count query"

      log = with_active_record_log do
        results = schema.execute("{
          items(first: 3) {
            nodes {
              __typename
            }
          }
        }")
      end
      assert_equal ["Item", "Item", "Item"], results["data"]["items"]["nodes"].map { |i| i["__typename"] }
      assert_equal 1, log.split("\n").size, "It runs only one query"

      log = with_active_record_log do
        results = schema.execute("{
          items(first: 11, maxPageSizeOverride: 11) {
            nodes {
              __typename
            }
            pageInfo {
              hasNextPage
            }
          }
        }")
      end
      assert_equal ["Item"] * 10, results["data"]["items"]["nodes"].map { |i| i["__typename"] }
      assert_equal 1, log.split("\n").size, "It runs only one query when less than total count is requested"
      assert_equal 0, log.scan("COUNT(").size, "It runs no count query"

      log = with_active_record_log do
        results = schema.execute("{
          items(first: 3) {
            nodes {
              __typename
            }
            pageInfo {
              hasNextPage
            }
          }
        }")
      end
      assert_equal ["Item", "Item", "Item"], results["data"]["items"]["nodes"].map { |i| i["__typename"] }
      assert_equal true, results["data"]["items"]["pageInfo"]["hasNextPage"]
      assert_equal 1, log.split("\n").size, "It loads `first + 1` nodes and uses the extra one for hasNextPage"
    end

    describe "loading one extra node for hasNextPage" do
      def run_logged(query_str, run_schema = schema)
        results = nil
        log = with_active_record_log do
          results = run_schema.execute(query_str)
        end
        [results["data"]["items"], log.split("\n")]
      end

      it "runs one query when pageInfo is selected before nodes or edges" do
        ["nodes { name }", "edges { node { name } }"].each do |page_selection|
          items, queries = run_logged("{ items(first: 3) { pageInfo { hasNextPage } #{page_selection} } }")

          assert_equal true, items["pageInfo"]["hasNextPage"]
          assert_equal 3, (items["nodes"] || items["edges"]).size
          assert_equal 1, queries.size, "#{page_selection}: #{queries.inspect}"
          assert_includes queries.first, '["LIMIT", 4]'
        end
      end

      it "returns false for a full last page without a second query" do
        items, queries = run_logged("{ items(first: 10, maxPageSizeOverride: 10) { pageInfo { hasNextPage } nodes { name } } }")

        assert_equal false, items["pageInfo"]["hasNextPage"]
        assert_equal 10, items["nodes"].size
        assert_equal 1, queries.size
      end

      it "doesn't peek when hasNextPage isn't selected" do
        items, queries = run_logged("{ items(first: 3) { nodes { name } } }")

        assert_equal 3, items["nodes"].size
        assert_equal 1, queries.size
        assert_includes queries.first, '["LIMIT", 3]'
      end

      it "runs one query when only a cursor loads the page" do
        items, queries = run_logged("{ items(first: 3) { pageInfo { hasNextPage endCursor } } }")

        assert_equal true, items["pageInfo"]["hasNextPage"]
        assert_equal 1, queries.size, queries.inspect
        assert_includes queries.first, '["LIMIT", 4]'
      end

      it "doesn't peek when nodes are skipped" do
        items, queries = run_logged("{ items(first: 3) { pageInfo { hasNextPage } nodes @skip(if: true) { name } } }")

        assert_equal true, items["pageInfo"]["hasNextPage"]
        assert_equal 1, queries.size
        assert_equal 1, queries.first.squeeze.scan("SELECT 1 AS").size, "It's an exist query (#{queries.inspect})"
      end

      it "respects a limit already on the relation" do
        cursor = schema.execute("{ items(first: 1) { pageInfo { endCursor } } }")["data"]["items"]["pageInfo"]["endCursor"]

        [1, 2, 3, 5].each do |relation_limit|
          limited_schema = ConnectionAssertions.build_schema(
            connection_class: GraphQL::Pagination::ActiveRecordRelationConnection,
            total_count_connection_class: RelationConnectionWithTotalCount,
            get_items: -> { Food.all.limit(relation_limit) }
          )
          [[2, nil], [2, cursor], [3, cursor]].each do |first, after|
            args = "first: #{first}#{after ? ", after: #{after.inspect}" : ""}"
            peeked, peeked_queries = run_logged("{ items(#{args}) { pageInfo { hasNextPage } nodes { name } } }", limited_schema)
            counted, _queries = run_logged("{ items(#{args}) { pageInfo { hasNextPage } } }", limited_schema)

            # A page cut short by the relation's limit is the last page (the old check ignores that limit)
            expected = relation_limit < first ? false : counted["pageInfo"]["hasNextPage"]
            assert_equal expected, peeked["pageInfo"]["hasNextPage"], "limit(#{relation_limit}), #{args}"
            assert_equal 1, peeked_queries.size, "limit(#{relation_limit}), #{args}: #{peeked_queries.inspect}"
          end
        end
      end
    end

    describe "already-loaded ActiveRecord relations" do
      ALREADY_LOADED_QUERY_STRING = "
      query($first: Int, $after: String, $last: Int, $before: String) {
            preloadedItems(first: $first, after: $after, last: $last, before: $before) {
              pageInfo {
                hasPreviousPage
                hasNextPage
                endCursor
              }
              nodes { __typename }
            }
          }
      "
      it "only runs one query for already-loaded unbounded queries" do
        results = nil
        log = with_active_record_log do
          results = schema.execute(ALREADY_LOADED_QUERY_STRING)
        end
        # The default_page_size of 4 is applied to the results
        assert_equal 4, results["data"]["preloadedItems"]["nodes"].size
        assert_equal 1, log.split("\n").size, "It runs only one query"
        decolorized_log = log.gsub(/\e\[([;\d]+)?m/, '').chomp
        assert_operator decolorized_log, :end_with?, 'SELECT "foods".* FROM "foods"', "it's an unbounded select from the resolver"
      end

      it "only runs one query for already-loaded `last:...` queries" do
        results = nil
        log = with_active_record_log do
          results = schema.execute(ALREADY_LOADED_QUERY_STRING, variables: { last: 1 })
        end
        assert_equal 1, results["data"]["preloadedItems"]["nodes"].size
        assert_equal 1, log.split("\n").size, "It runs only one query"
        decolorized_log = log.gsub(/\e\[([;\d]+)?m/, '').chomp
        assert_operator decolorized_log, :end_with?, 'SELECT "foods".* FROM "foods"', "it's an unbounded select from the resolver"
      end

      it "only runs one query for already-loaded `first:... / after:` queries" do
        results = nil
        log = with_active_record_log do
          results = schema.execute(ALREADY_LOADED_QUERY_STRING, variables: { first: 1 })
        end
        assert_equal 1, results["data"]["preloadedItems"]["nodes"].size
        assert_equal 1, log.split("\n").size, "It runs only one query"
        decolorized_log = log.gsub(/\e\[([;\d]+)?m/, '').chomp
        assert_operator decolorized_log, :end_with?, 'SELECT "foods".* FROM "foods"', "it's an unbounded select from the resolver"

        cursor = results["data"]["preloadedItems"]["pageInfo"]["endCursor"]
        log = with_active_record_log do
          results = schema.execute(ALREADY_LOADED_QUERY_STRING, variables: { first: 1, after: cursor })
        end
        assert_equal 1, results["data"]["preloadedItems"]["nodes"].size
        assert_equal 1, log.split("\n").size, "It runs only one query"
        decolorized_log = log.gsub(/\e\[([;\d]+)?m/, '').chomp
        assert_operator decolorized_log, :end_with?, 'SELECT "foods".* FROM "foods"', "it's an unbounded select from the resolver"
        assert_equal "[\"2\"]+nonce", results["data"]["preloadedItems"]["pageInfo"]["endCursor"], "it makes the right cursor"
      end

      let(:schema) {
        ConnectionAssertions.build_schema(
          connection_class: GraphQL::Pagination::ActiveRecordRelationConnection,
          total_count_connection_class: RelationConnectionWithTotalCount,
          get_items: -> {
            relation = if Food.respond_to?(:scoped)
              Food.scoped # Rails 3-friendly version of .all
            else
              Food.all
            end
            relation.load
            relation
          }
        )
      }

      include ConnectionAssertions
    end

    if RUBY_VERSION >= "3.2.0"
      require "async"

      describe "when Fibers share a connection" do
        let(:async_context) {
          async_schema = Class.new(schema) { use GraphQL::Dataloader::AsyncDataloader }
          GraphQL::Query.new(async_schema, "{ __typename }").context
        }

        class SlowCountingRelationConnection < GraphQL::Pagination::ActiveRecordRelationConnection
          attr_reader :count_calls

          private

          def relation_count(relation)
            @count_calls = (@count_calls || 0) + 1
            sleep(0.05)
            super
          end
        end

        it "loads the page only once when several Fibers resolve it" do
          connection = GraphQL::Pagination::ActiveRecordRelationConnection.new(Food.all, first: 2, max_page_size: 10, context: async_context)
          results = []

          log = with_active_record_log do
            Sync do
              3.times.map { Async { results << connection.nodes } }.each(&:wait)
            end
          end

          assert_equal 1, log.split("\n").size, "It runs one query"
          assert_equal [2, 2, 2], results.map(&:size)
        end

        it "loads the page once and doesn't count when nodes and hasNextPage resolve in separate Fibers" do
          connection = SlowCountingRelationConnection.new(Food.all, first: 2, max_page_size: 10, context: async_context)
          connection.lookahead = Class.new { def selects?(_field_name); true; end; def selection(_field_name); self; end }.new
          nodes = nil
          has_next_page = nil

          log = with_active_record_log do
            Sync do
              [
                Async { has_next_page = connection.has_next_page },
                Async { nodes = connection.nodes },
              ].each(&:wait)
            end
          end

          assert_equal 1, log.split("\n").size, "It runs one query"
          assert_nil connection.count_calls
          assert_equal 2, nodes.size
          assert_equal true, has_next_page
        end

        it "counts the relation only once when page fields resolve in separate Fibers" do
          connection = SlowCountingRelationConnection.new(Food.all, last: 2, max_page_size: 10, context: async_context)
          nodes = nil
          has_previous_page = nil

          Sync do
            [
              Async { nodes = connection.nodes },
              Async { has_previous_page = connection.has_previous_page },
            ].each(&:wait)
          end

          assert_equal 1, connection.count_calls
          assert_equal 2, nodes.size
          assert_equal true, has_previous_page
        end
      end
    end
  end
end
