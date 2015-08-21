require 'spec_helper'

describe GraphQL::Query::Projection do
  let(:query_string) { "
    query getProjections {
      projector {
        projectedInt,
        projector {
          projectedInt,
          resolvedInt,
          ... on Projector {
            ... projectedIntField
          }
        }
      }
      otherProjector: projector {
        projectedInt
        ... projectedIntField
        resolvedInt
      }
    }

    fragment projectedIntField on Projector {
      projectedInt2
    }
  "}
  let(:schema) { ProjectorSchema }

  let(:result) { GraphQL::Query.new(schema, query_string, context: { counter: 0 } ).result }

  describe "does book stuff" do
    let(:schema) { ReaderSchema }
    let(:query_string) { %|
      {
        currentReader {
          name
          books(first: 2) {
            name,
            author { name }
          }
        }
      }
    |}

    it "does book stuff" do
      pp result
      pp COUNT_LOGGER.count
    end
  end

  it "adds projected values to context.projections" do
    expected = {"data"=>
      {
        "projector"=>{
          "projectedInt"=>3,
          "projector"=>{
            "projectedInt"=>4,
            "projectedInt2"=>5,
            "resolvedInt"=>9,
          }
        },
        "otherProjector"=>{
          "projectedInt"=>6,
          "projectedInt2"=>7,
          "resolvedInt"=>10,
        }
      }
    }
    assert_equal(expected, result)
  end
end
