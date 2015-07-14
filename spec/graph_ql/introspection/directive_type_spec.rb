require 'spec_helper'

describe GraphQL::Introspection::DirectiveType do
  let(:query_string) {%|
    query getDirectives {
      __schema {
        directives { name, args { name, type { name, ofType { name } } }, onField, onFragment, onOperation }
      }
    }
  |}
  let(:result) { GraphQL::Query.new(DummySchema, query_string).result }

  it 'shows directive info ' do
    expected = { "data" => {"getDirectives" => {
      "__schema" => {
        "directives" => [
          {
            "name" => "skip",
            "args" => [
              {"name"=>"if", "type"=>{"name"=>"Non-Null", "ofType"=>{"name"=>"Boolean"}}}
            ],
            "onField" => true,
            "onFragment" => true,
            "onOperation" => false,
          },
          {
            "name" => "include",
            "args" => [
              {"name"=>"if", "type"=>{"name"=>"Non-Null", "ofType"=>{"name"=>"Boolean"}}}
            ],
            "onField" => true,
            "onFragment" => true,
            "onOperation" => false,
          },
        ]
      }
    }}}
    assert_equal(expected, result)
  end
end
