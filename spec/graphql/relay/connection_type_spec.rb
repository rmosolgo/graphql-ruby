require "spec_helper"

describe GraphQL::Relay::ConnectionType do
  describe ".create_type" do
    describe "connections with custom Edge classes / EdgeTypes" do
      let(:query_string) {%|
        {
          rebels {
            basesWithCustomEdge {
              totalCountTimes100
              edges {
                upcasedName
                upcasedParentName
                edgeClassName
                node {
                  name
                }
              }
            }
          }
        }
      |}

      it "uses the custom edge and custom connection" do
        result = star_wars_query(query_string)
        bases = result["data"]["rebels"]["basesWithCustomEdge"]
        assert_equal 200, bases["totalCountTimes100"]
        assert_equal ["YAVIN", "ECHO BASE"] , bases["edges"].map { |e| e["upcasedName"] }
        assert_equal ["Yavin", "Echo Base"] , bases["edges"].map { |e| e["node"]["name"] }
        assert_equal ["CustomBaseEdge", "CustomBaseEdge"] , bases["edges"].map { |e| e["edgeClassName"] }
        upcased_rebels_name = "ALLIANCE TO RESTORE THE REPUBLIC"
        assert_equal [upcased_rebels_name, upcased_rebels_name] , bases["edges"].map { |e| e["upcasedParentName"] }

      end
    end
  end
end
