require "spec_helper"

describe GraphQL::UnionType do
  let(:type_1) { OpenStruct.new(kind: GraphQL::TypeKinds::OBJECT)}
  let(:type_2) { OpenStruct.new(kind: GraphQL::TypeKinds::OBJECT)}
  let(:type_3) { OpenStruct.new(kind: GraphQL::TypeKinds::SCALAR)}
  let(:union) {
    types = [type_1, type_2]
    GraphQL::UnionType.define {
      name("MyUnion")
      description("Some items")
      possible_types(types)
    }
  }

  it "has a name" do
    assert_equal("MyUnion", union.name)
  end

  it '#include? returns true if type in in possible_types' do
    assert union.include?(type_1)
  end

  it '#include? returns false if type is not in possible_types' do
    assert_equal(false, union.include?(type_3))
  end

  describe "typecasting from union to union" do
    let(:result) { DummySchema.execute(query_string) }
    let(:query_string) {%|
      {
        allDairy {
          dairyName: __typename
          ... on Beverage {
            bevName: __typename
            ... on Milk {
              flavors
            }
          }
        }
      }
    |}

    it "casts if the object belongs to both unions" do
      expected_result = [
        {"dairyName"=>"Cheese"},
        {"dairyName"=>"Cheese"},
        {"dairyName"=>"Cheese"},
        {"dairyName"=>"Milk", "bevName"=>"Milk", "flavors"=>["Natural", "Chocolate", "Strawberry"]},
        {"dairyName"=>"Milk", "bevName"=>"Milk", "flavors"=>["Natural"]},
      ]

      assert_equal expected_result, result["data"]["allDairy"]
    end
  end

  describe "list of union type" do
    describe "fragment spreads" do
      let(:result) { DummySchema.execute(query_string) }
      let(:query_string) {%|
        {
          allDairy {
            __typename
            ... milkFields
            ... cheeseFields
          }
        }
        fragment milkFields on Milk {
          id
          source
          origin
          flavors
        }

        fragment cheeseFields on Cheese {
          id
          source
          origin
          flavor
        }
      |}

      it "resolves the right fragment on the right item" do
        all_dairy = result["data"]["allDairy"]
        cheeses = all_dairy.first(3)
        cheeses.each do |cheese|
          assert_equal "Cheese", cheese["__typename"]
          assert_equal ["__typename", "id", "source", "origin", "flavor"], cheese.keys
        end

        milks = all_dairy.last(1)
        milks.each do |milk|
          assert_equal "Milk", milk["__typename"]
          assert_equal ["__typename", "id", "source", "origin", "flavors"], milk.keys
        end
      end
    end
  end
end
