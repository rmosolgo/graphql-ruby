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
                cursor
              }
            }
          }
        }
      |}

      it "uses the custom edge and custom connection" do
        result = query(query_string)
        bases = result["data"]["rebels"]["basesWithCustomEdge"]
        assert_equal 300, bases["totalCountTimes100"]
        assert_equal ["YAVIN", "ECHO BASE", "SECRET HIDEOUT"] , bases["edges"].map { |e| e["upcasedName"] }
        assert_equal ["Yavin", "Echo Base", "Secret Hideout"] , bases["edges"].map { |e| e["node"]["name"] }
        assert_equal ["CustomBaseEdge"] , bases["edges"].map { |e| e["edgeClassName"] }.uniq
        upcased_rebels_name = "ALLIANCE TO RESTORE THE REPUBLIC"
        assert_equal [upcased_rebels_name] , bases["edges"].map { |e| e["upcasedParentName"] }.uniq
      end
    end
  end
end
