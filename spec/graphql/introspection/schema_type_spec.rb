# frozen_string_literal: true
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
  let(:result) { Dummy::Schema.execute(query_string) }

  it "exposes the schema" do
    expected = { "data" => {
      "__schema" => {
        "types" => Dummy::Schema.types.values.map { |t| t.name.nil? ? (p t; raise("no name for #{t}")) : {"name" => t.name} },
        "queryType"=>{
          "fields"=>[
            {"name"=>"allAnimal"},
            {"name"=>"allAnimalAsCow"},
            {"name"=>"allDairy"},
            {"name"=>"allEdible"},
            {"name"=>"allEdibleAsMilk"},
            {"name"=>"cheese"},
            {"name"=>"cow"},
            {"name"=>"dairy"},
            {"name"=>"deepNonNull"},
            {"name"=>"error"},
            {"name"=>"executionError"},
            {"name"=>"executionErrorWithExtensions"},
            {"name"=>"executionErrorWithOptions"},
            {"name"=>"favoriteEdible"},
            {"name"=>"fromSource"},
            {"name"=>"maybeNull"},
            {"name"=>"milk"},
            {"name"=>"multipleErrorsOnNonNullableField"},
            {"name"=>"root"},
            {"name"=>"searchDairy"},
            {"name"=>"tracingScalar"},
            {"name"=>"valueWithExecutionError"},
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
