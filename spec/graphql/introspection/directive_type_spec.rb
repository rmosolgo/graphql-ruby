require "spec_helper"

describe GraphQL::Introspection::DirectiveType do
  let(:query_string) {%|
    query getDirectives {
      __schema {
        directives {
          name,
          args { name, type { name, ofType { name } } },
          locations
          # Deprecated fields:
          onField
          onFragment
          onOperation
        }
      }
    }
  |}
  let(:result) { DummySchema.execute(query_string) }

  it "shows directive info " do
    expected = { "data" => {
      "__schema" => {
        "directives" => [
          {
            "name" => "include",
            "args" => [
              {"name"=>"if", "type"=>{"name"=>"Non-Null", "ofType"=>{"name"=>"Boolean"}}}
            ],
            "locations"=>["FIELD", "FRAGMENT_SPREAD", "INLINE_FRAGMENT"],
            "onField" => true,
            "onFragment" => true,
            "onOperation" => false,
          },
          {
            "name" => "skip",
            "args" => [
              {"name"=>"if", "type"=>{"name"=>"Non-Null", "ofType"=>{"name"=>"Boolean"}}}
            ],
            "locations"=>["FIELD", "FRAGMENT_SPREAD", "INLINE_FRAGMENT"],
            "onField" => true,
            "onFragment" => true,
            "onOperation" => false,
          },
        ]
      }
    }}
    assert_equal(expected, result)
  end
end
