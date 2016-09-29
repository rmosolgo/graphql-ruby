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
end
