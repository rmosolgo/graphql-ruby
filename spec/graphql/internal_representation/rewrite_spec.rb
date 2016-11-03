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

      root_children = op_node.typed_children[DairyAppQueryType]
      assert_equal 2, root_children.length
      assert_equal DairyAppQueryType, op_node.return_type
      first_field = root_children.values.first
      assert_equal 3, first_field.typed_children[CheeseType].length
      assert_equal DairyAppQueryType, first_field.owner_type
      assert_equal CheeseType, first_field.return_type

      second_field = root_children.values.last
      assert_equal 1, second_field.typed_children[CheeseType].length
      assert_equal DairyAppQueryType.get_field("cheese"), second_field.definition
      assert_equal CheeseType, second_field.return_type
      assert second_field.inspect.is_a?(String)
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
      cheese_field = rewrite_result[nil].typed_children[DairyAppQueryType]["cheese"]
      typename_field = cheese_field.typed_children[CheeseType]["typename"]
      assert_equal "__typename", typename_field.definition.name
      assert_equal "__typename", typename_field.definition_name
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

      cheese2: cheese(id: 2) {
        similarCheese(source: COW) {
          id
        }
        ... cheese2Fields
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

    fragment cheese2InnerFields on Cheese {
      id
      fatContent
    }

    fragment cheese2Fields on Cheese {
      similarCheese(source: COW) {
        ... cheese2InnerFields
      }
    }

    |}

    it "puts all fragment members as children" do
      op_node = rewrite_result[nil]

      cheese_field = op_node.typed_children[DairyAppQueryType]["cheese"]
      assert_equal ["id1", "id2", "fatContent", "similarCow", "flavor"], cheese_field.typed_children[CheeseType].keys
      assert_equal ["fatContent", "origin"], cheese_field.typed_children[EdibleInterface].keys
      # Merge:
      similar_cow_field = cheese_field.typed_children[CheeseType]["similarCow"]
      assert_equal ["similarCowSource", "fatContent", "similarCheese", "id"], similar_cow_field.typed_children[CheeseType].keys
      # Deep merge:
      similar_sheep_field = similar_cow_field.typed_children[CheeseType]["similarCheese"]
      assert_equal ["flavor", "source"], similar_sheep_field.typed_children[CheeseType].keys

      edible_origin_node = cheese_field.typed_children[EdibleInterface]["origin"]
      assert_equal EdibleInterface.get_field("origin"), edible_origin_node.definition
      assert_equal EdibleInterface, edible_origin_node.owner_type

      edible_fat_content_node = cheese_field.typed_children[EdibleInterface]["fatContent"]
      assert_equal EdibleInterface.get_field("fatContent"), edible_fat_content_node.definition
      assert_equal EdibleInterface, edible_fat_content_node.owner_type

      cheese_fat_content_node = cheese_field.typed_children[CheeseType]["fatContent"]
      assert_equal CheeseType.get_field("fatContent"), cheese_fat_content_node.definition
      assert_equal CheeseType, cheese_fat_content_node.owner_type

      cheese_flavor_node = cheese_field.typed_children[CheeseType]["flavor"]
      assert_equal CheeseType.get_field("flavor"), cheese_flavor_node.definition
      assert_equal CheeseType, cheese_flavor_node.owner_type


      # nested spread inside fragment definition:
      cheese_2_field = op_node.typed_children[DairyAppQueryType]["cheese2"].typed_children[CheeseType]["similarCheese"]
      assert_equal ["id", "fatContent"], cheese_2_field.typed_children[CheeseType].keys
    end
  end

  describe "nested fields on typed fragments" do
    let(:result) { DummySchema.execute(query_string) }
    let(:query_string) {%|
    {
      allDairy {
        __typename

        ... on Milk {
          selfAsEdible {
            milkInlineOrigin: origin
          }
        }

        ... on Cheese {
          selfAsEdible {
            cheeseInlineOrigin: origin
          }
        }

        ... on Edible {
          selfAsEdible {
            edibleInlineOrigin: origin
          }
        }

        ... {
          ... on Edible {
            selfAsEdible {
              untypedInlineOrigin: origin
            }
          }
        }
        ...milkFields
        ...cheeseFields
      }
    }

    fragment cheeseFields on Cheese {
      selfAsEdible {
        cheeseFragmentOrigin: origin
      }
    }
    fragment milkFields on Milk {
      selfAsEdible {
        milkFragmentOrigin: origin
      }
    }
    |}

    it "distinguishes between nested fields with the same name on different typed fragments" do
      all_dairy = result["data"]["allDairy"]
      cheeses = all_dairy.select { |d| d["__typename"] == "Cheese" }
      milks = all_dairy.select { |d| d["__typename"] == "Milk" }

      # Make sure all the data is there:
      assert_equal 3, cheeses.length
      assert_equal 1, milks.length

      cheeses.each do |cheese|
        assert_equal ["cheeseInlineOrigin", "cheeseFragmentOrigin", "edibleInlineOrigin", "untypedInlineOrigin"], cheese["selfAsEdible"].keys
      end
      milks.each do |milk|
        assert_equal ["milkInlineOrigin", "milkFragmentOrigin", "edibleInlineOrigin", "untypedInlineOrigin"], milk["selfAsEdible"].keys
      end
    end
  end
end
