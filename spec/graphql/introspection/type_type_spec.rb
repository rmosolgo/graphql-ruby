require 'spec_helper'

describe GraphQL::Introspection::TypeType do
  let(:query_string) {%|
     query introspectionQuery {
       cheeseType:    __type(name: "Cheese") { name, kind, fields { name, isDeprecated, type { name, ofType { name } } } }
       milkType:      __type(name: "Milk") { interfaces { name }, fields { type { name, ofType { name } } } }
       dairyAnimal:   __type(name: "DairyAnimal") { name, kind, enumValues(includeDeprecated: false) { name, isDeprecated } }
       dairyProduct:  __type(name: "DairyProduct") { name, kind, possibleTypes { name } }
       animalProduct: __type(name: "AnimalProduct") { name, kind, possibleTypes { name }, fields { name } }
     }
  |}
  let(:result) { DummySchema.execute(query_string, context: {}, variables: {"cheeseId" => 2}) }
  let(:cheese_fields) {[
    {"name"=>"deeplyNullableCheese", "isDeprecated"=>false, "type"=>{"name"=>"Cheese", "ofType"=>nil}},
    {"name"=>"flavor",      "isDeprecated" => false, "type" => { "name" => "Non-Null", "ofType" => { "name" => "String"}}},
    {"name"=>"id",          "isDeprecated" => false, "type" => { "name" => "Non-Null", "ofType" => { "name" => "Int"}}},
    {"name"=>"nullableCheese", "isDeprecated"=>false, "type"=>{"name"=>"Cheese", "ofType"=>nil}},
    {"name"=>"origin",      "isDeprecated" => false, "type" => { "name" => "Non-Null", "ofType" => { "name" => "String"}}},
    {"name"=>"similarCheese", "isDeprecated"=>false, "type"=>{"name"=>"Cheese", "ofType"=>nil}},
    {"name"=>"source",      "isDeprecated" => false, "type" => { "name" => "Non-Null", "ofType" => { "name" => "DairyAnimal"}}},
  ]}

  let(:dairy_animals) {[
    {"name"=>"COW",   "isDeprecated"=> false },
    {"name"=>"GOAT",  "isDeprecated"=> false },
    {"name"=>"SHEEP", "isDeprecated"=> false },
  ]}
  it 'exposes metadata about types' do
    expected = {"data"=> {
      "cheeseType" => {
        "name"=> "Cheese",
        "kind" => "OBJECT",
        "fields"=> cheese_fields
      },
      "milkType"=>{
        "interfaces"=>[
          {"name"=>"Edible"},
          {"name"=>"AnimalProduct"}
        ],
        "fields"=>[
          {"type"=>{"name"=>"Non-Null", "ofType"=>{"name"=>"Float"}}},
          {"type"=>{"name"=>"List", "ofType"=>{"name"=>"String"}}},
          {"type"=>{"name"=>"Non-Null", "ofType"=>{"name"=>"ID"}}},
          {"type"=>{"name"=>"Non-Null", "ofType"=>{"name"=>"String"}}},
          {"type"=>{"name"=>"DairyAnimal", "ofType"=>nil}},
        ]
      },
      "dairyAnimal"=>{
        "name"=>"DairyAnimal",
        "kind"=>"ENUM",
        "enumValues"=> dairy_animals,
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
        "fields"=>[
          {"name"=>"source"},
        ]
      }
    }}
    assert_equal(expected, result)
  end

  describe 'deprecated fields' do
    let(:query_string) {%|
       query introspectionQuery {
         cheeseType:    __type(name: "Cheese") { name, kind, fields(includeDeprecated: true) { name, isDeprecated, type { name, ofType { name } } } }
         dairyAnimal:   __type(name: "DairyAnimal") { name, kind, enumValues(includeDeprecated: true) { name, isDeprecated } }
       }
    |}
    let(:deprecated_fields) { {"name"=>"fatContent", "isDeprecated"=>true, "type"=>{"name"=>"Non-Null", "ofType"=>{"name"=>"Float"}}} }
    it 'can expose deprecated fields' do
      new_cheese_fields = ([deprecated_fields] + cheese_fields).sort_by { |f| f['name'] }
      expected = { "data" => {
        "cheeseType" => {
          "name"=> "Cheese",
          "kind" => "OBJECT",
          "fields"=> new_cheese_fields
        },
        "dairyAnimal"=>{
          "name"=>"DairyAnimal",
          "kind"=>"ENUM",
          "enumValues"=> dairy_animals + [{"name" => "YAK", "isDeprecated" => true}],
        },
      }}
      assert_equal(expected, result)
    end
  end
end
