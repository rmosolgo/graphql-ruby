require 'spec_helper'

describe GraphQL::InputObjectType do
  let(:input_object) { DairyProductInputType }
  it 'has a description' do
    assert(input_object.description)
  end

  it 'has input fields' do
    assert(DairyProductInputType.input_fields["fatContent"])
  end

  describe "when sent into a query" do
    let(:variables) { {} }
    let(:result) { DummySchema.execute(query_string, variables: variables) }

    describe "list inputs" do
      let(:variables) { {"search" => [{"source" => "COW"}]} }
      let(:query_string) {%|
        query getCheeses($search: [DairyProductInput]!){
            sheep: searchDairy(product: [{source: SHEEP, fatContent: 0.1}]) {
              ... cheeseFields
            }
            cow: searchDairy(product: $search) {
              ... cheeseFields
            }
        }

        fragment cheeseFields on Cheese {
          flavor
        }
      |}

      it "converts items to plain values" do
        sheep_value = result["data"]["sheep"]["flavor"]
        cow_value = result["data"]["cow"]["flavor"]
        assert_equal("Manchego", sheep_value)
        assert_equal("Brie", cow_value)
      end
    end

    describe "scalar inputs" do
      let(:query_string) {%|
        {
          cheese(id: 1.4) {
            flavor
          }
        }
      |}

      it "converts them to the correct type" do
        cheese_name = result["data"]["cheese"]["flavor"]
        assert_equal("Brie", cheese_name)
      end
    end
  end
end
