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
    let(:query_string) {%|
    {
        sheep: searchDairy(product: [{source: SHEEP, fatContent: 0.1}]) {
          ... cheeseFields
        }
        cow: searchDairy(product: [{source: COW}]) {
          ... cheeseFields
        }
    }

    fragment cheeseFields on Cheese {
      flavor
    }
    |}
    let(:result) { DummySchema.execute(query_string) }

    it "converts nested list values" do
      sheep_value = result["data"]["sheep"]["flavor"]
      cow_value = result["data"]["cow"]["flavor"]
      assert_equal("Manchego", sheep_value)
      assert_equal("Brie", cow_value)
    end
  end
end
