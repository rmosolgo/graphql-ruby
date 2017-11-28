# frozen_string_literal: true
require "spec_helper"

describe GraphQL::InternalRepresentation::Rewrite do
  let(:schema) {
    GraphQL::Schema.from_definition <<-GRAPHQL
    type Query {
      plant(id: ID!): Plant
      fruit(id: ID!): [Fruit!]
    }

    union Plant = Grain | Fruit | Vegetable | Nut

    interface Tree {
      name: String!
      leafType: LeafType
      habitats: [Habitat]
    }

    enum LeafType {
      NEEDLE
      LEAF
    }

    type Fruit implements Tree {
      name: String!
      color: [Int!]!
      leafType: LeafType
      habitats: [Habitat]
    }

    type Vegetable {
      name: String!
      edibleParts: [String!]!
    }

    type Grain {
      name: String!
    }

    type Nut implements Tree {
      name: String!
      diameter: Int!
      leafType: LeafType
      habitats: [Habitat]
    }

    interface Environ {
      seasons: [String]
    }

    type Habitat implements Environ {
      residentName: String!
      averageWeight: Int!
      seasons: [String]
    }
    GRAPHQL

  }
  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: schema) }
  let(:query) { GraphQL::Query.new(schema, query_string) }
  let(:rewrite_result) {
    res = validator.validate(query)
    res[:errors].any? && raise(res[:errors].map(&:message).join("; "))
    res[:irep]
  }

  describe "building a tree over concrete types with fragments" do
    let(:query_string) {
      <<-GRAPHQL
      query getPlant($id: ID!) {
        plant(id: $id) {
          __typename
          ... on Tree {
            leafType
            habitats {
              averageWeight
            }
          }
          ... on Fruit {
            name
            color
            ... on Tree {
              leafType
            }
          }
          ... on Nut {
            leafType
            ...NutFields
          }
        }
      }

      fragment NutFields on Nut {
        leafType
        ... TreeFields
      }

      fragment TreeFields on Tree {
        habitats {
          ... HabitatFields
        }
      }

      fragment HabitatFields on Habitat {
        seasons
      }
      GRAPHQL
    }

    it "groups selections by object types which they apply to" do
      doc = rewrite_result.operation_definitions["getPlant"]
      assert_nil doc.definition

      plant_scoped_selection = doc.scoped_children[schema.types["Query"]]["plant"]
      assert_equal ["Fruit", "Nut", "Plant"], plant_scoped_selection.scoped_children.keys.map(&:name).sort

      plant_selection = doc.typed_children[schema.types["Query"]]["plant"]
      assert_equal ["Fruit", "Grain", "Nut", "Vegetable"], plant_selection.typed_children.keys.map(&:name).sort

      fruit_selections = plant_selection.typed_children[schema.types["Fruit"]]
      assert_equal ["__typename", "color", "habitats", "leafType", "name"], fruit_selections.keys.sort
      assert_equal 2, fruit_selections["leafType"].ast_nodes.size

      nut_selections = plant_selection.typed_children[schema.types["Nut"]]
      # `... on Tree`, `... on Nut`, and `NutFields`, but not `... on Fruit { ... on Tree }`
      assert_equal 3, nut_selections["leafType"].ast_nodes.size
      # Multi-level merging when including fragments:
      habitats_selections = nut_selections["habitats"].typed_children[schema.types["Habitat"]]
      assert_equal ["averageWeight", "seasons"], habitats_selections.keys
    end

    it "tracks parent nodes" do
      doc = rewrite_result.operation_definitions["getPlant"]
      assert_nil doc.parent

      plant_selection = doc.typed_children[schema.types["Query"]]["plant"]
      assert_equal doc, plant_selection.parent

      leaf_type_selection = plant_selection.typed_children[schema.types["Nut"]]["leafType"]
      assert_equal plant_selection, leaf_type_selection.parent

      habitats_selection = plant_selection.typed_children[schema.types["Nut"]]["habitats"]
      assert_equal plant_selection, habitats_selection.parent

      seasons_selection = habitats_selection.typed_children[schema.types["Habitat"]]["seasons"]
      average_weight_selection = habitats_selection.typed_children[schema.types["Habitat"]]["averageWeight"]
      assert_equal habitats_selection, seasons_selection.parent
      assert_equal habitats_selection, average_weight_selection.parent
    end

    it "tracks field return type" do
      doc = rewrite_result.operation_definitions["getPlant"]

      assert plant_selection = doc.typed_children[schema.types["Query"]]["plant"]
      assert_equal "Plant", plant_selection.return_type.to_s

      assert tree_selection = plant_selection.typed_children[schema.types["Fruit"]]
      assert_equal "[Int!]!", tree_selection["color"].return_type.to_s
    end
  end

  describe "tracking directives on fragment spreads" do
    let(:query_string) { <<-GRAPHQL
      query getPlant($id: ID!) {
        plant(id: $id) {
          ... on Nut @skip(if: true) {
            leafType
          }

          ... on Tree {
            leafType @include(if: true)
          }

          ... on Nut {
            leafType # no directives
          }

          ... NutFields @include(if: false)
        }
      }
      fragment NutFields on Nut {
        leafType @skip(if: false)
      }
    GRAPHQL
    }

    it "applies directives from all contexts" do
      doc = rewrite_result.operation_definitions["getPlant"]
      plant_selection = doc.typed_children[schema.types["Query"]]["plant"]
      leaf_type_selection = plant_selection.typed_children[schema.types["Nut"]]["leafType"]
      # Only unskipped occurrences in the AST
      assert_equal 2, leaf_type_selection.ast_nodes.size
    end
  end

  describe "deep fragment merging" do
    let(:query_string) { <<-GRAPHQL
      {
        plant(id: 1) {
          ...TreeFields
          ...NutFields
        }
      }

      fragment TreeFields on Tree {
        habitats {
          seasons
        }
      }

      fragment NutFields on Nut {
        habitats {
          residentName
          ... HabitatFields
        }
      }

      fragment HabitatFields on Habitat {
        averageWeight
      }
      GRAPHQL
    }

    it "applies spreads to their parents only" do
      doc = rewrite_result.operation_definitions[nil]
      plant_selection = doc.typed_children[schema.types["Query"]]["plant"]
      nut_habitat_selections = plant_selection.typed_children[schema.types["Nut"]]["habitats"].typed_children[schema.types["Habitat"]]
      assert_equal ["averageWeight", "residentName", "seasons"], nut_habitat_selections.keys.sort
      fruit_habitat_selections = plant_selection.typed_children[schema.types["Fruit"]]["habitats"].typed_children[schema.types["Habitat"]]
      assert_equal ["seasons"], fruit_habitat_selections.keys
    end
  end

  describe "nested fields on typed fragments" do
    let(:result) { Dummy::Schema.execute(query_string) }
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

      expected_cheese_fields = ["cheeseFragmentOrigin", "cheeseInlineOrigin", "edibleInlineOrigin", "untypedInlineOrigin"]
      cheeses.each do |cheese|
        assert_equal expected_cheese_fields, cheese["selfAsEdible"].keys.sort
      end

      expected_milk_fields = ["edibleInlineOrigin", "milkFragmentOrigin", "milkInlineOrigin", "untypedInlineOrigin"]
      milks.each do |milk|
        assert_equal expected_milk_fields, milk["selfAsEdible"].keys.sort
      end
    end
  end

  describe "fragment merging bug" do
    let(:query_string) {
      <<-GRAPHQL
      {
        ...Frag1
        __type(name: "Query") {
          ...Frag2
        }
      }

      fragment Frag1 on Query {
        __type(name: "Query") {
          ...Frag2
        }
      }

      fragment Frag2 on __Type {
        __typename
      }
      GRAPHQL
    }

    it "finishes" do
      doc = rewrite_result.operation_definitions[nil]
      type_node = doc.typed_children[schema.types["Query"]]["__type"]
      typename_node = type_node.typed_children[schema.types["__Type"]]["__typename"]
      assert_equal 1, typename_node.ast_nodes.size
      assert_equal 15, typename_node.ast_node.line
      assert_equal 9, typename_node.ast_node.col
    end
  end

  describe "fragment definition without query" do
    let(:query_string) {
      <<-GRAPHQL
      fragment NutFields on Nut {
        leafType
        ... TreeFields
      }

      fragment TreeFields on Tree {
        habitats {
          ... HabitatFields
        }
      }

      fragment HabitatFields on Habitat {
        seasons
      }
      GRAPHQL
    }

    let(:validator) {
      rules = GraphQL::StaticValidation::ALL_RULES - [
        GraphQL::StaticValidation::FragmentsAreUsed
      ]
      GraphQL::StaticValidation::Validator.new(schema: schema, rules: rules)
    }

    it "tracks fragment definitions without operation" do
      doc = rewrite_result.fragment_definitions["NutFields"]

      assert doc.typed_children[schema.types["Nut"]]["leafType"]

      assert nut_selections = doc.typed_children[schema.types["Nut"]]
      habitats_selections = nut_selections["habitats"].typed_children[schema.types["Habitat"]]
      assert_equal ["seasons"], habitats_selections.keys
    end
  end
end
