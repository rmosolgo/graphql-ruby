# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Analysis::AST::QueryComplexity do
  let(:schema) { Dummy::Schema }
  let(:reduce_result) { GraphQL::Analysis::AST.analyze_query(query, [GraphQL::Analysis::AST::QueryComplexity]) }
  let(:reduce_multiplex_result) {
    GraphQL::Analysis::AST.analyze_multiplex(multiplex, [GraphQL::Analysis::AST::QueryComplexity])
  }
  let(:variables) { {} }
  let(:query) { GraphQL::Query.new(schema, query_string, variables: variables) }
  let(:multiplex) {
    GraphQL::Execution::Multiplex.new(
      schema: schema,
      queries: [query.dup, query.dup],
      context: {},
      max_complexity: 10
    )
  }

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
      complexities = reduce_result.first
      assert_equal 7, complexities
    end

    describe "when skipped by directives" do
      let(:variables) { { "isSkipped" => true } }
      it "doesn't include skipped fields" do
        complexity = reduce_result.first
        assert_equal 3, complexity
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
      complexity = reduce_result.first
      assert_equal 10, complexity
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

            # 1 for honey, aspartame
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
        complexity = reduce_result.first
        assert_equal 6, complexity
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

            # 1 for honey, aspartame
            ... on Sweetener { sweetness }
          }
        }
      |}

      it "gets the max among interface types" do
        complexity = reduce_result.first
        assert_equal 4, complexity
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
        complexity = reduce_result.first
        assert_equal 3, complexity
      end
    end

    describe "redundant fields not within a fragment" do
      let(:query_string) {%|
      {
        cheese {
          id
        }

        cheese {
          id
        }
      }
      |}

      it "only counts them once" do
        complexity = reduce_result.first
        assert_equal 2, complexity
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
      complexity = reduce_result.first
      assert_equal 7, complexity
    end
  end

  describe "calucation complexity for a multiplex" do
    let(:query_string) {%|
      query cheeses {
        cheese(id: 1) {
          id
          flavor
          source
        }
      }
    |}


    it "sums complexity for both queries" do
      complexity = reduce_multiplex_result.first
      assert_equal 8, complexity
    end

    describe "abstract type" do
      let(:query_string) {%|
        query Edible {
          allEdible {
            origin
            fatContent
          }
        }
      |}
      it "sums complexity for both queries" do
        complexity = reduce_multiplex_result.first
        assert_equal 6, complexity
      end
    end
  end

  describe "custom complexities" do
    class CustomComplexitySchema < GraphQL::Schema
      module ComplexityInterface
        include GraphQL::Schema::Interface
        field :value, Int, null: true
      end

      class SingleComplexity < GraphQL::Schema::Object
        field :value, Int, null: true, complexity: 0.1
        field :complexity, SingleComplexity, null: true do
          argument :value, Int, required: false
          complexity(->(ctx, args, child_complexity) { args[:value] + child_complexity })
        end
        implements ComplexityInterface
      end

      class DoubleComplexity < GraphQL::Schema::Object
        field :value, Int, null: true, complexity: 4
        implements ComplexityInterface
      end

      class Query < GraphQL::Schema::Object
        field :complexity, SingleComplexity, null: true do
          argument :value, Int, required: false
          complexity ->(ctx, args, child_complexity) { args[:value] + child_complexity }
        end

        field :inner_complexity, ComplexityInterface, null: true do
          argument :value, Int, required: false
        end
      end

      query(Query)
      orphan_types(DoubleComplexity)
      use(GraphQL::Execution::Interpreter)
      use(GraphQL::Analysis::AST)
    end

    let(:query) { GraphQL::Query.new(complexity_schema, query_string) }
    let(:complexity_schema) { CustomComplexitySchema }
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
      complexity = reduce_result.first
      # 10 from `complexity`, `0.3` from `value`
      assert_equal 10.3, complexity
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
        complexity = reduce_result.first
        # 1 for innerComplexity + 4 for DoubleComplexity.value
        assert_equal 5, complexity
      end
    end
  end

  describe "field_complexity hook" do
    class CustomComplexityAnalyzer < GraphQL::Analysis::AST::QueryComplexity
      def initialize(query)
        super
        @field_complexities_by_query = {}
      end

      def result
        super
        @field_complexities_by_query[@query]
      end

      private

      def field_complexity(scoped_type_complexity, max_complexity:, child_complexity:)
        @field_complexities_by_query[scoped_type_complexity.query] ||= {}
        @field_complexities_by_query[scoped_type_complexity.query][scoped_type_complexity.response_path] = {
          max_complexity: max_complexity,
          child_complexity: child_complexity,
        }
      end
    end

    let(:reduce_result) { GraphQL::Analysis::AST.analyze_query(query, [CustomComplexityAnalyzer]) }

    let(:query_string) {%|
    {
      cheese {
        id
      }

      cheese {
        id
        flavor
      }
    }
    |}
    it "gets called for each field with complexity data" do
      field_complexities = reduce_result.first

      assert_equal({
        ['cheese', 'id'] => { max_complexity: 1, child_complexity: nil },
        ['cheese', 'flavor'] => { max_complexity: 1, child_complexity: nil },
        ['cheese'] => { max_complexity: 3, child_complexity: 2 },
      }, field_complexities)
    end
  end
end
