require 'spec_helper'

describe GraphQL::SchemaType do
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
    expected = { "data" => { "getSchema" => {
      "__schema" => {
        "types" => DummySchema.types.values.map { |t| t.name.nil? ? (p t; raise("no name for #{t}")) : {"name" => t.name} },
        "queryType"=>{
          "fields"=>[
            {"name"=>"cheese"},
            {"name"=>"fromSource"},
            {"name"=>"favoriteEdible"},
            {"name"=>"searchDairy"},
            {"name"=>"__typename"},
            {"name"=>"__type"},
            {"name"=>"__schema"},
          ]
        },
        "mutationType" => nil,
      }
    }}}
    assert_equal(expected, result)
  end
end
