# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Relay::ConnectionType do
  describe ".create_type" do
    describe "connections with custom Edge classes / EdgeTypes" do
      let(:query_string) {%|
        {
          rebels {
            basesWithCustomEdge {
              totalCountTimes100
              fieldName
              edges {
                upcasedName
                upcasedParentName
                edgeClassName
                node {
                  name
                }
                cursor
              }
            }
          }
        }
      |}

      it "uses the custom edge and custom connection" do
        result = star_wars_query(query_string)
        bases = result["data"]["rebels"]["basesWithCustomEdge"]
        assert_equal 300, bases["totalCountTimes100"]
        assert_equal 'basesWithCustomEdge', bases["fieldName"]
        assert_equal ["YAVIN", "ECHO BASE", "SECRET HIDEOUT"] , bases["edges"].map { |e| e["upcasedName"] }
        assert_equal ["Yavin", "Echo Base", "Secret Hideout"] , bases["edges"].map { |e| e["node"]["name"] }
        assert_equal ["StarWars::CustomBaseEdge"] , bases["edges"].map { |e| e["edgeClassName"] }.uniq
        upcased_rebels_name = "ALLIANCE TO RESTORE THE REPUBLIC"
        assert_equal [upcased_rebels_name] , bases["edges"].map { |e| e["upcasedParentName"] }.uniq
      end
    end

    describe "connections with nodes field" do
      let(:query_string) {%|
        {
          rebels {
            bases: basesWithCustomEdge {
              nodes {
                name
              }
            }
          }
        }
      |}

      it "uses the custom edge and custom connection" do
        result = star_wars_query(query_string)
        bases = result["data"]["rebels"]["bases"]
        assert_equal ["Yavin", "Echo Base", "Secret Hideout"] , bases["nodes"].map { |e| e["name"] }
      end
    end


    describe "when an execution error is raised" do
      let(:query_string) {%|
        {
          basesWithNullName {
            edges {
              node {
                name
              }
            }
          }
        }
      |}

      it "nullifies the parent and adds an error" do
        result = star_wars_query(query_string)
        assert_equal nil, result["data"]["basesWithNullName"]["edges"][0]["node"]
        assert_equal "Boom!", result["errors"][0]["message"]
      end
    end

    describe "when an execution error is returned" do
      let(:query_string) { <<-GRAPHQL
        query getError($error: String!){
          rebels {
            ships(nameIncludes: $error) {
              edges {
                node {
                  name
                }
              }
            }
          }
        }
      GRAPHQL
      }

      it "adds an error" do
        result = star_wars_query(query_string, { "error" => "error"})
        assert_equal 1, result["errors"].length
        assert_equal "error from within connection", result["errors"][0]["message"]
      end

      it "adds an error for a lazy error" do
        result = star_wars_query(query_string, { "error" => "lazyError"})
        assert_equal 1, result["errors"].length
        assert_equal "lazy error from within connection", result["errors"][0]["message"]
      end
    end
  end
end
