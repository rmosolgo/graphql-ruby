require "spec_helper"


describe GraphQL::Introspection::InputValueType do
  let(:query_string) {%|
     {
       __type(name: "DairyProductInput") {
         name,
         description,
         kind,
         inputFields {
           name,
           type { name },
           defaultValue
         }
       }
     }
  |}
  let(:result) { DummySchema.execute(query_string)}

  it 'exposes metadata about input objects, giving extra quotes for strings' do
    expected = { "data" => {
        "__type" => {
          "name"=>"DairyProductInput",
          "description"=>"Properties for finding a dairy product",
          "kind"=>"INPUT_OBJECT",
          "inputFields"=>[
            {"name"=>"source", "type"=>{ "name" => "Non-Null"}, "defaultValue"=>nil},
            {"name"=>"originDairy", "type"=>{ "name" => "String"}, "defaultValue"=>"\"Sugar Hollow Dairy\""},
            {"name"=>"fatContent", "type"=>{ "name" => "Float"}, "defaultValue"=>nil}
          ]
        }
      }}
    assert_equal(expected, result)
  end
end
