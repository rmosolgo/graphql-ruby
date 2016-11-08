require "spec_helper"

describe GraphQL::Execution::Boxed do
  class Box
    def initialize(item)
      @item = item
    end

    def item
      @item
    end
  end

  class SumAll
    ALL = []
    attr_reader :own_value
    attr_accessor :value

    def initialize(own_value)
      @own_value = own_value
      ALL << self
    end

    def value
      @value ||= begin
        total_value = ALL.map(&:own_value).reduce(&:+)
        ALL.each { |v| v.value = total_value}
        ALL.clear
        total_value
      end
      @value
    end
  end

  BoxedSum = GraphQL::ObjectType.define do
    name "BoxedSum"
    field :value, !types.Int do
      resolve ->(o, a, c) { o }
    end
    field :nestedSum, BoxedSum do
      argument :value, !types.Int
      resolve ->(o, args, c) { SumAll.new(o + args[:value]) }
    end
  end

  BoxedQuery = GraphQL::ObjectType.define do
    name "Query"

    field :int, !types.Int do
      argument :value, !types.Int
      argument :plus, types.Int, default_value: 0
      resolve ->(o, args, c) { Box.new(args[:value] + args[:plus]) }
    end

    field :sum, !types.Int do
      argument :value, !types.Int
      resolve ->(o, args, c) { SumAll.new(args[:value]) }
    end

    field :nestedSum, BoxedSum do
      argument :value, !types.Int
      resolve ->(o, args, c) { SumAll.new(args[:value]) }
    end

    field :listSum, types[BoxedSum] do
      argument :values, types[types.Int]
      resolve ->(o, args, c) { args[:values] }
    end
  end

  BoxedSchema = GraphQL::Schema.define do
    query(BoxedQuery)
    boxed_value(Box, :item)
    boxed_value(SumAll, :value)
  end

  def run_query(query_str)
    BoxedSchema.execute(query_str)
  end

  describe "unboxing" do
    it "calls value handlers" do
      res = run_query('{  int(value: 2, plus: 1)}')
      assert_equal 3, res["data"]["int"]
    end

    it "can do out-of-bounds processing" do
      res = run_query %|
      {
        a: sum(value: 2)
        b: sum(value: 4)
        c: sum(value: 6)
      }
      |

      assert_equal [12, 12, 12], res["data"].values
    end

    it "can do nested boxed values" do
      res = run_query %|
      {
        a: nestedSum(value: 3) {
          value
          nestedSum(value: 7) {
            value
          }
        }
        b: nestedSum(value: 2) {
          value
          nestedSum(value: 11) {
            value
          }
        }

        c: listSum(values: [1,2]) {
          nestedSum(value: 3) {
            value
          }
        }
      }
      |

      expected_data = {
        "a"=>{"value"=>14, "nestedSum"=>{"value"=>46}},
        "b"=>{"value"=>14, "nestedSum"=>{"value"=>46}},
        "c"=>[{"nestedSum"=>{"value"=>14}}, {"nestedSum"=>{"value"=>14}}],
      }

      assert_equal expected_data, res["data"]
    end

    it "propagates nulls"
  end
end
