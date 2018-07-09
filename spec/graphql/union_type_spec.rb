# frozen_string_literal: true
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

  it '#resolve_type raises error if resolved type is not in possible_types' do
    test_str = 'Hello world'
    union.resolve_type = ->(value, ctx) {
      "This is not the types you are looking for"
    }
    fake_ctx = OpenStruct.new(query: GraphQL::Query.new(Dummy::Schema, ""))

    assert_raises(RuntimeError) {
      union.resolve_type(test_str, fake_ctx)
    }
  end

  describe "#resolve_type" do
    let(:result) { Dummy::Schema.execute(query_string) }
    let(:query_string) {%|
      {
        allAnimal {
          type: __typename
          ... on Cow {
            cowName: name
          }
          ... on Goat {
            goatName: name
          }
        }

        allAnimalAsCow {
          type: __typename
          ... on Cow {
            name
          }
        }
      }
    |}

    it 'returns correct types for general schema and specific union' do
      expected_result = {
        # When using Query#resolve_type
        "allAnimal" => [
          { "type" => "Cow", "cowName" => "Billy" },
          { "type" => "Goat", "goatName" => "Gilly" }
        ],

        # When using UnionType#resolve_type
        "allAnimalAsCow" => [
          { "type" => "Cow", "name" => "Billy" },
          { "type" => "Cow", "name" => "Gilly" }
        ]
      }
      assert_equal expected_result, result["data"]
    end
  end

  describe "typecasting from union to union" do
    let(:result) { Dummy::Schema.execute(query_string) }
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
      ]
      assert_equal expected_result, result["data"]["allDairy"]
    end
  end

  describe "list of union type" do
    describe "fragment spreads" do
      let(:result) { Dummy::Schema.execute(query_string) }
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

  describe "#dup" do
    it "copies possible types without affecting the original" do
      union.possible_types # load the internal cache
      union_2 = union.dup
      union_2.possible_types << type_3
      assert_equal 2, union.possible_types.size
      assert_equal 3, union_2.possible_types.size
    end
  end

  describe "#get_possible_type" do
    let(:query_string) {%|
      {
        __type(name: "Beverage") {
          name
        }
      }
    |}

    let(:query) { GraphQL::Query.new(Dummy::Schema, query_string) }
    let(:union) { Dummy::BeverageUnion }

    it "returns the type definition if the type exists and is a possible type of the union" do
      assert union.get_possible_type("Milk", query.context)
    end

    it "returns nil if the type is not found in the schema" do
      assert_nil union.get_possible_type("Foo", query.context)
    end

    it "returns nil if the type is not a possible type of the union" do
      assert_nil union.get_possible_type("Cheese", query.context)
    end
  end

  describe "#possible_type?" do
    let(:query_string) {%|
      {
        __type(name: "Beverage") {
          name
        }
      }
    |}

    let(:query) { GraphQL::Query.new(Dummy::Schema, query_string) }
    let(:union) { Dummy::BeverageUnion }

    it "returns true if the type exists and is a possible type of the union" do
      assert union.possible_type?("Milk", query.context)
    end

    it "returns false if the type is not found in the schema" do
      refute union.possible_type?("Foo", query.context)
    end

    it "returns false if the type is not a possible type of the union" do
      refute union.possible_type?("Cheese", query.context)
    end
  end
end
