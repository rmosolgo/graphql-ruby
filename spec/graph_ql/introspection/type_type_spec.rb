require 'spec_helper'

describe GraphQL::TypeType do
  let(:query_string) {%|
     query introspectionQuery {
       cheeseType:    __type(name: "Cheese") { name, kind, fields { name, isDeprecated, type { name, ofType { name } } } }
       dairyAnimal:   __type(name: "DairyAnimal") { name, kind }
       dairyProduct:  __type(name: "DairyProduct") { name, kind, possibleTypes { name } }
       animalProduct: __type(name: "AnimalProduct") { name, kind, possibleTypes { name }, fields { name } }
     }
  |}
  let(:query) { GraphQL::Query.new(DummySchema, query_string, context: {}, params: {"cheeseId" => 2})}
  let(:cheese_fields) {[
    {"name"=>"id",          "isDeprecated" => false, "type" => { "name" => "Non-Null", "ofType" => { "name" => "Int"}}},
    {"name"=>"flavor",      "isDeprecated" => false, "type" => { "name" => "Non-Null", "ofType" => { "name" => "String"}}},
    {"name"=>"source",      "isDeprecated" => false, "type" => { "name" => "Non-Null", "ofType" => { "name" => "DairyAnimal"}}},
  ]}
  it 'exposes metadata about types' do
    res = query.execute
    expected = { "introspectionQuery" => {
      "cheeseType" => {
        "name"=> "Cheese",
        "kind" => "OBJECT",
        "fields"=> cheese_fields
      },
      "dairyAnimal"=>{
        "name"=>"DairyAnimal",
        "kind"=>"ENUM"
      },
      "dairyProduct"=>{
        "name"=>"DairyProduct",
        "kind"=>"UNION",
        "possibleTypes"=>[{"name"=>"Milk"}, {"name"=>"Cheese"}],
      },
      "animalProduct" => {
        "name"=>"AnimalProduct",
        "kind"=>"INTERFACE",
        "possibleTypes"=>[{"name"=>"Cheese"}, {"name"=>"Milk"}],
        "fields"=>[{"name"=>"source"}]
      }
    }}
    assert_equal(expected, res)
  end

  describe 'deprecated fields' do
    let(:query_string) {%|
       query introspectionQuery {
         cheeseType:    __type(name: "Cheese") { name, kind, fields(includeDeprecated: true) { name, isDeprecated, type { name, ofType { name } } } }
       }
    |}
    let(:deprecated_fields) { {"name"=>"fatContent", "isDeprecated"=>true, "type"=>{"name"=>"Non-Null", "ofType"=>{"name"=>"Float"}}} }
    it 'can expose deprecated fields' do
      expected = { "introspectionQuery" => {
        "cheeseType" => {
          "name"=> "Cheese",
          "kind" => "OBJECT",
          "fields"=> cheese_fields + [deprecated_fields]
        },
      }}
      assert_equal(expected, query.execute)
    end

    describe 'input objects' do
      let(:query_string) {%|
         query introspectionQuery {
           __type(name: "DairyProductInput") { name, description, kind, inputFields { name, type { name }, defaultValue } }
         }
      |}

      it 'exposes metadata about input objects' do
        res = query.execute
        expected = { "introspectionQuery" => {
            "__type" => {
              "name"=>"DairyProductInput",
              "description"=>"Properties for finding a dairy product",
              "kind"=>"INPUT_OBJECT",
              "inputFields"=>[
                {"name"=>"source", "type"=>{ "name" => "DairyAnimal"}, "defaultValue"=>nil},
                {"name"=>"fatContent", "type"=>{ "name" => "Float"}, "defaultValue"=>nil}
              ]
            }
          }
        }
        assert_equal(expected, res)
      end
    end
  end
end
