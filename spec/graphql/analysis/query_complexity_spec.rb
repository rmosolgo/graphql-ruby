require "spec_helper"

describe GraphQL::Analysis::QueryComplexity do
  let(:complexities) { [] }
  let(:query_complexity) { GraphQL::Analysis::QueryComplexity.new { |this_query, complexity|  complexities << this_query << complexity } }
  let(:reduce_result) { GraphQL::Analysis.reduce_query(query, [query_complexity]) }
  let(:query) { GraphQL::Query.new(DummySchema, query_string) }

  describe "simple queries" do
    let(:query_string) {%|
      {
        # complexity of 3
        cheese1: cheese(id: 1) {
          id
          flavor
        }

        # complexity of 4
        cheese2: cheese(id: 2) {
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

    describe "mutually exclusive object types" do
      let(:query_string) {%|
        {
          favoriteEdible {
            fatContent

            ... on Edible {
              origin
            }

            ... on Cheese {
              id
              flavor
            }

            ... milkFields
            ... cheeseFields
          }
        }

        fragment milkFields on Milk {
          source
          flavors
        }

        fragment cheeseFields on Cheese {
          source
        }
      |}

      it "gets the max among options" do
        reduce_result
        assert_equal 6, complexities.last
      end
    end
  end

  describe "custom complexities" do
    let(:query) { GraphQL::Query.new(complexity_schema, query_string) }
    let(:complexity_schema) {
      complexity_type = GraphQL::ObjectType.define do
        name "Complexity"
        field :value, types.Int do
          complexity 0.1
          resolve -> (obj, args, ctx) { obj }
        end
        field :complexity, -> { complexity_type } do
          argument :value, types.Int
          complexity -> (ctx, args, child_complexity) { args[:value] + child_complexity }
          resolve -> (obj, args, ctx) { args[:value] }
        end
      end

      query_type = GraphQL::ObjectType.define do
        name "Query"
        field :complexity, -> { complexity_type } do
          argument :value, types.Int
          complexity -> (ctx, args, child_complexity) { args[:value] + child_complexity }
          resolve -> (obj, args, ctx) { args[:value] }
        end
      end

      GraphQL::Schema.new(query: query_type)
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
  end
end
