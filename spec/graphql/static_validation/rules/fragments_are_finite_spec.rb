require "spec_helper"

describe GraphQL::StaticValidation::FragmentsAreFinite do
  include StaticValidationHelpers

  let(:query_string) {%|
    query getCheese {
      cheese(id: 1) {
        ... idField
        ... sourceField
        similarCheese(source: SHEEP) {
          ... flavorField
        }
      }
    }

    fragment sourceField on Cheese {
      source,
      ... flavorField
      ... idField
    }
    fragment flavorField on Cheese {
      flavor,
      similarCheese(source: SHEEP) {
        ... on Cheese {
          ... sourceField
        }
      }
    }
    fragment idField on Cheese {
      id
    }
  |}

  it "doesnt allow infinite loops" do
    expected = [
      {
        "message"=>"Fragment sourceField contains an infinite loop",
        "locations"=>[{"line"=>12, "column"=>5}],
        "fields"=>["fragment sourceField"],
      },
      {
        "message"=>"Fragment flavorField contains an infinite loop",
        "locations"=>[{"line"=>17, "column"=>5}],
        "fields"=>["fragment flavorField"],
      }
    ]
    assert_equal(expected, errors)
  end

  describe "undefined spreads inside fragments" do
    let(:query_string) {%|
      {
        cheese(id: 1) { ... frag1 }
      }
      fragment frag1 on Cheese { id, ...frag2 }
    |}

    it "doesn't blow up" do
      assert_equal("Fragment frag2 was used, but not defined", errors.first["message"])
    end
  end
end
