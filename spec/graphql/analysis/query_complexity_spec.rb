# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Analysis::QueryComplexity do
  let(:complexities) { [] }
  let(:query_complexity) { GraphQL::Analysis::QueryComplexity.new { |this_query, complexity|  complexities << this_query << complexity } }
  let(:reduce_result) { GraphQL::Analysis.analyze_query(query, [query_complexity]) }
  let(:variables) { {} }
  let(:query) { GraphQL::Query.new(Dummy::Schema, query_string, variables: variables) }

  describe "simple queries" do
    let(:query_string) {%|
      query cheeses($isSkipped: Boolean = false){
        # complexity of 3
        cheese1: cheese(id: 1) {
          id
          flavor
        }

        # complexity of 4
        cheese2: cheese(id: 2) @skip(if: $isSkipped) {
          similarCheese(source: SHEEP) {
            ... on Cheese {
              similarCheese(source: SHEEP) {
                id
              }
            }
          }
        }
      }
    |}

    it "sums the complexity" do
      reduce_result
      assert_equal complexities, [query, 7]
    end

    describe "when skipped by directives" do
      let(:variables) { { "isSkipped" => true } }
      it "doesn't include skipped fields" do
        reduce_result
        assert_equal complexities, [query, 3]
      end
    end
  end

  describe "query with fragments" do
    let(:query_string) {%|
      {
        # complexity of 3
        cheese1: cheese(id: 1) {
          id
          flavor
        }

        # complexity of 7
        cheese2: cheese(id: 2) {
          ... cheeseFields1
          ... cheeseFields2
        }
      }

      fragment cheeseFields1 on Cheese {
        similarCow: similarCheese(source: COW) {
          id
          ... cheeseFields2
        }
      }

      fragment cheeseFields2 on Cheese {
        similarSheep: similarCheese(source: SHEEP) {
          id
        }
      }
    |}

    it "counts all fragment usages, not the definitions" do
      reduce_result
      assert_equal complexities, [query, 10]
    end

    describe "mutually exclusive types" do
      let(:query_string) {%|
        {
          favoriteEdible {
            # 1 for everybody
            fatContent

            # 1 for everybody
            ... on Edible {
              origin
            }

            # 1 for honey
            ... on Sweetener {
              sweetness
            }

            # 2 for milk
            ... milkFields
            # 1 for cheese
            ... cheeseFields
            # 1 for honey
            ... honeyFields
            # 1 for milk + cheese
            ... dairyProductFields
          }
        }

        fragment milkFields on Milk {
          id
          source
        }

        fragment cheeseFields on Cheese {
          source
        }

        fragment honeyFields on Honey {
          flowerType
        }

        fragment dairyProductFields on DairyProduct {
          ... on Cheese {
            flavor
          }

          ... on Milk {
            flavors
          }
        }
      |}

      it "gets the max among options" do
        reduce_result
        assert_equal 6, complexities.last
      end
    end


    describe "when there are no selections on any object types" do
      let(:query_string) {%|
        {
          # 1 for everybody
          favoriteEdible {
            # 1 for everybody
            fatContent

            # 1 for everybody
            ... on Edible { origin }

            # 1 for honey
            ... on Sweetener { sweetness }
          }
        }
      |}

      it "gets the max among interface types" do
        reduce_result
        assert_equal 4, complexities.last
      end
    end

    describe "redundant fields" do
      let(:query_string) {%|
      {
        favoriteEdible {
          fatContent
          # this is executed separately and counts separately:
          aliasedFatContent: fatContent

          ... on Edible {
            fatContent
          }

          ... edibleFields
        }
      }

      fragment edibleFields on Edible {
        fatContent
      }
      |}

      it "only counts them once" do
        reduce_result
        assert_equal 3, complexities.last
      end
    end
  end

  describe "relay types" do
    let(:query) { GraphQL::Query.new(StarWars::Schema, query_string) }
    let(:query_string) {%|
    {
      rebels {
        ships {
          edges {
            node {
              id
            }
          }
          pageInfo {
            hasNextPage
          }
        }
      }
    }
    |}

    it "gets the complexity" do
      reduce_result
      assert_equal 7, complexities.last
    end
  end

  describe "custom complexities" do
    let(:query) { GraphQL::Query.new(complexity_schema, query_string) }
    let(:complexity_schema) {
      complexity_interface = GraphQL::InterfaceType.define do
        name "ComplexityInterface"
        field :value, types.Int
      end

      single_complexity_type = GraphQL::ObjectType.define do
        name "SingleComplexity"
        field :value, types.Int, complexity: 0.1 do
          resolve ->(obj, args, ctx) { obj }
        end
        field :complexity, single_complexity_type do
          argument :value, types.Int
          complexity ->(ctx, args, child_complexity) { args[:value] + child_complexity }
          resolve ->(obj, args, ctx) { args[:value] }
        end
        interfaces [complexity_interface]
      end

      double_complexity_type = GraphQL::ObjectType.define do
        name "DoubleComplexity"
        field :value, types.Int, complexity: 4 do
          resolve ->(obj, args, ctx) { obj }
        end
        interfaces [complexity_interface]
      end

      query_type = GraphQL::ObjectType.define do
        name "Query"
        field :complexity, single_complexity_type do
          argument :value, types.Int
          complexity ->(ctx, args, child_complexity) { args[:value] + child_complexity }
          resolve ->(obj, args, ctx) { args[:value] }
        end

        field :innerComplexity, complexity_interface do
          argument :value, types.Int
          resolve ->(obj, args, ctx) { args[:value] }
        end
      end

      GraphQL::Schema.define(
        query: query_type,
        orphan_types: [double_complexity_type],
        resolve_type: ->(a,b,c) { :pass }
      )
    }
    let(:query_string) {%|
      {
        a: complexity(value: 3) { value }
        b: complexity(value: 6) {
          value
          complexity(value: 1) {
            value
          }
        }
      }
    |}

    it "sums the complexity" do
      reduce_result
      # 10 from `complexity`, `0.3` from `value`
      assert_equal complexities, [query, 10.3]
    end

    describe "same field on multiple types" do
      let(:query_string) {%|
      {
        innerComplexity(value: 2) {
          ... on SingleComplexity { value }
          ... on DoubleComplexity { value }
        }
      }
      |}

      it "picks them max for those fields" do
        reduce_result
        # 1 for innerComplexity + 4 for DoubleComplexity.value
        assert_equal complexities, [query, 5]
      end
    end
  end
end
