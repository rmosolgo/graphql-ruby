require 'spec_helper'

describe GraphQL::TypeType do
  let(:query_string) {%|
     query introspectionQuery {
       cheeseType:    __type(name: "Cheese") { name, kind }
       dairyAnimal:   __type(name: "DairyAnimal") { name, kind }
       dairyProduct:  __type(name: "DairyProduct") { name, kind }
     }
  |}
  let(:query) { GraphQL::Query.new(DummySchema, query_string, context: {}, params: {"cheeseId" => 2})}

  it 'exposes metadata about types' do
    res = query.execute
    expected = { "introspectionQuery" => {
      "cheeseType" => {
        "name"=> "Cheese",
        "kind" => "OBJECT"
      },
      "dairyAnimal"=>{
        "name"=>"DairyAnimal",
        "kind"=>"ENUM"
      },
      "dairyProduct"=>{
        "name"=>"DairyProduct",
        "kind"=>"UNION"
      }
    }}
    assert_equal(expected, res)
  end
end
