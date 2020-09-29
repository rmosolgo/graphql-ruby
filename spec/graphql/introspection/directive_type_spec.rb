# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Introspection::DirectiveType do
  let(:query_string) {%|
    query getDirectives {
      __schema {
        directives {
          name,
          args { name, type { kind, name, ofType { name } } },
          locations
          # Deprecated fields:
          onField
          onFragment
          onOperation
        }
      }
    }
  |}

  let(:schema) { Class.new(Dummy::Schema) }
  let(:result) { schema.execute(query_string) }
  before do
    schema.max_depth(100)
  end

  it "shows directive info " do
    expected = { "data" => {
      "__schema" => {
        "directives" => [
          {
            "name" => "include",
            "args" => [
              {"name"=>"if", "type"=>{"kind"=>"NON_NULL", "name"=>nil, "ofType"=>{"name"=>"Boolean"}}}
            ],
            "locations"=>["FIELD", "FRAGMENT_SPREAD", "INLINE_FRAGMENT"],
            "onField" => true,
            "onFragment" => true,
            "onOperation" => false,
          },
          {
            "name" => "skip",
            "args" => [
              {"name"=>"if", "type"=>{"kind"=>"NON_NULL", "name"=>nil, "ofType"=>{"name"=>"Boolean"}}}
            ],
            "locations"=>["FIELD", "FRAGMENT_SPREAD", "INLINE_FRAGMENT"],
            "onField" => true,
            "onFragment" => true,
            "onOperation" => false,
          },
          {
            "name" => "deprecated",
            "args" => [
              {"name"=>"reason", "type"=>{"kind"=>"SCALAR", "name"=>"String", "ofType"=>nil}}
            ],
            "locations"=>["FIELD_DEFINITION", "ENUM_VALUE", "ARGUMENT_DEFINITION", "INPUT_FIELD_DEFINITION"],
            "onField" => false,
            "onFragment" => false,
            "onOperation" => false,
          },
        ]
      }
    }}
    assert_equal(expected, result)
  end
end
