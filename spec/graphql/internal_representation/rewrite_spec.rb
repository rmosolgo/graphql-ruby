require "spec_helper"

describe GraphQL::InternalRepresentation::Rewrite do
  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema) }
  let(:query) { GraphQL::Query.new(DummySchema, query_string) }
  let(:rewrite_result) {
    validator.validate(query)[:irep]
  }
  describe "plain queries" do
    let(:query_string) {%|
    query getCheeses {
      cheese1: cheese(id: 1) {
        id1: id
        id2: id
        id3: id
      }
      cheese2: cheese(id: 2) {
        id
      }
    }
    |}
    it "produces a tree of nodes" do
      op_node = rewrite_result["getCheeses"]

      assert_equal 2, op_node.children.length
      assert_equal QueryType, op_node.return_type
      first_field = op_node.children.values.first
      assert_equal 3, first_field.children.length
      assert_equal [QueryType], first_field.on_types.to_a
      assert_equal CheeseType, first_field.return_type

      second_field = op_node.children.values.last
      assert_equal 1, second_field.children.length
      assert_equal [QueryType], second_field.on_types.to_a
      assert_equal CheeseType, second_field.return_type
    end
  end

  describe "dynamic fields" do
    let(:query_string) {%|
      {
        cheese(id: 1) {
          typename: __typename
        }
      }
    |}

    it "gets dynamic field definitions" do
      cheese_field = rewrite_result[nil].children["cheese"]
      typename_field = cheese_field.children["typename"]
      assert_equal "__typename", typename_field.field.name
    end
  end

  describe "merging fragments" do
    let(:query_string) {%|
    {
      cheese(id: 1) {
        id1: id
        ... {
          id2: id
        }

        fatContent
        ... on Edible {
          fatContent
          origin
        }
        ... cheeseFields

        ... similarCheeseField
      }
    }

    fragment cheeseFields on Cheese {
      fatContent
      flavor
      similarCow: similarCheese(source: COW) {
        similarCowSource: source,
        id
        ... similarCowFields
      }
    }

    fragment similarCowFields on Cheese {
      similarCheese(source: SHEEP) {
        source
      }
    }

    fragment similarCheeseField on Cheese {
      # deep fragment merge
      similarCow: similarCheese(source: COW) {
        similarCowSource: source,
        fatContent
        similarCheese(source: SHEEP) {
          flavor
        }
      }
    }
    |}

    it "puts all fragment members as children" do
      op_node = rewrite_result[nil]

      cheese_field = op_node.children["cheese"]
      assert_equal ["id1", "id2", "fatContent", "origin", "similarCow", "flavor"], cheese_field.children.keys
      # Merge:
      similar_cow_field = cheese_field.children["similarCow"]
      assert_equal ["similarCowSource", "fatContent", "similarCheese", "id"], similar_cow_field.children.keys
      # Deep merge:
      similar_sheep_field = similar_cow_field.children["similarCheese"]
      assert_equal ["flavor", "source"], similar_sheep_field.children.keys

      assert_equal Set.new([EdibleInterface]), cheese_field.children["origin"].on_types
      assert_equal Set.new([CheeseType, EdibleInterface]), cheese_field.children["fatContent"].on_types
      assert_equal Set.new([CheeseType]), cheese_field.children["flavor"].on_types
    end
  end
end
