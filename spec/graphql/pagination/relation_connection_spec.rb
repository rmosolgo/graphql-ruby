# frozen_string_literal: true
require "spec_helper"

if testing_rails?
  describe GraphQL::Pagination::RelationConnection do
    {
      "ActiveRecord" => [GraphQL::Pagination::ActiveRecordRelationConnection, -> { Food.order(:id).limit(3) }],
      "loaded ActiveRecord" => [GraphQL::Pagination::ActiveRecordRelationConnection, -> { Food.order(:id).limit(3).load }],
      "Sequel" => [GraphQL::Pagination::SequelDatasetConnection, -> { SequelDB[:foods].order(:id).limit(3) }],
    }.each do |name, (connection_class, get_items)|
      describe "with an application-provided limit on #{name}" do
        before do
          if Food.count == 0
            ConnectionAssertions::NAMES.each { |n| Food.create!(name: n) }
          end
        end

        let(:schema) do
          ConnectionAssertions.build_schema(
            connection_class: connection_class,
            total_count_connection_class: connection_class,
            get_items: get_items,
          )
        end

        {
          { after: 2 } => ["Cucumber"],
          { after: 3 } => [],
          { after: 5 } => [],
          { before: 3 } => ["Avocado", "Beet"],
          { before: 6 } => ["Avocado", "Beet", "Cucumber"],
          { after: 1, before: 6 } => ["Beet", "Cucumber"],
          { after: 2, before: 6, last: 1 } => ["Cucumber"],
        }.each do |arguments, expected_names|
          it "keeps #{arguments.inspect} within the relation" do
            variables = arguments.dup
            [:after, :before].each do |key|
              variables[key] = schema.cursor_encoder.encode(variables[key].to_s, nonce: true) if variables[key]
            end
            result = schema.execute(<<~GRAPHQL, variables: variables)
              query($after: String, $before: String, $last: Int) {
                unboundedItems(after: $after, before: $before, last: $last) { nodes { name } }
              }
            GRAPHQL

            assert_equal expected_names, result["data"]["unboundedItems"]["nodes"].map { |node| node["name"] }
          end
        end

        it "preserves an application-provided offset as well as the limit" do
          after_cursor = schema.cursor_encoder.encode("2", nonce: true)
          result = schema.execute(<<~GRAPHQL, variables: { after: after_cursor })
            query($after: String) {
              offsetItems(first: 3, after: $after) { nodes { name } pageInfo { hasNextPage endCursor } }
            }
          GRAPHQL
          items = result["data"]["offsetItems"]

          assert_equal ["Eggplant"], items["nodes"].map { |node| node["name"] }
          assert_equal false, items["pageInfo"]["hasNextPage"]
          assert_equal schema.cursor_encoder.encode("3", nonce: true), items["pageInfo"]["endCursor"]
        end

        it "checks hasNextPage within the relation with and without loading the page" do
          [[2, nil, true], [3, nil, false], [4, nil, false], [1, 1, true], [1, 2, false]].each do |first, after, expected|
            after_cursor = after && schema.cursor_encoder.encode(after.to_s, nonce: true)
            ["nodes { name }", "edges { node { name } }", ""].each do |selection|
              result = schema.execute(<<~GRAPHQL, variables: { first: first, after: after_cursor })
                query($first: Int, $after: String) {
                  items(first: $first, after: $after) { pageInfo { hasNextPage } #{selection} }
                }
              GRAPHQL

              assert_equal expected, result["data"]["items"]["pageInfo"]["hasNextPage"], "first: #{first}, after: #{after.inspect}, #{selection}"
            end
          end
        end
      end
    end
  end
end
