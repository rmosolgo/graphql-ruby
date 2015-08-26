require 'spec_helper'

describe GraphQL::Introspection::SchemaType do
  let(:query_string) {%|
    query getSchema {
      __schema {
        types { name }
        queryType { fields { name }}
        mutationType { fields { name }}
      }
    }
  |}
  let(:result) { GraphQL::Query.new(DummySchema, query_string).result }
  it 'exposes the schema' do
    expected = { "data" => {
      "__schema" => {
        "types" => DummySchema.types.values.map { |t| t.name.nil? ? (p t; raise("no name for #{t}")) : {"name" => t.name} },
        "queryType"=>{
          "fields"=>[
            {"name"=>"cheese"},
            {"name"=>"milk"},
            {"name"=>"fromSource"},
            {"name"=>"favoriteEdible"},
            {"name"=>"searchDairy"},
            {"name"=>"error"},
            {"name"=>"maybeNull"},
          ]
        },
        "mutationType"=> {
          "fields"=>[
            {"name"=>"pushValue"},
            {"name"=>"replaceValues"},
          ]
        },
      }
    }}
    assert_equal(expected, result)
  end
end
