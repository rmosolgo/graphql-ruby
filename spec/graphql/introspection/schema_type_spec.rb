require "spec_helper"

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
  let(:result) { DummySchema.execute(query_string) }

  it "exposes the schema" do
    expected_type_names = DummySchema
      .types
      .values
      .sort_by(&:name)
      .map { |t| t.name.nil? ? (p t; raise("no name for #{t}")) : {"name" => t.name} }

    expected = { "data" => {
      "__schema" => {
        "types" => expected_type_names,
        "queryType"=>{
          "fields"=>[
            {"name"=>"allDairy"},
            {"name"=>"allEdible"},
            {"name"=>"cheese"},
            {"name"=>"cow"},
            {"name"=>"dairy"},
            {"name"=>"deepNonNull"},
            {"name"=>"error"},
            {"name"=>"executionError"},
            {"name"=>"favoriteEdible"},
            {"name"=>"fromSource"},
            {"name"=>"maybeNull"},
            {"name"=>"milk"},
            {"name"=>"root"},
            {"name"=>"searchDairy"},
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
