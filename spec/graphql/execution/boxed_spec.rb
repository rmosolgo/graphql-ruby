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
    attr_reader :own_value
    attr_accessor :value

    def initialize(ctx, own_value)
      @own_value = own_value
      @all = ctx[:__sum_all__] ||= []
      @all << self
    end

    def value
      @value ||= begin
        total_value = @all.map(&:own_value).reduce(&:+)
        @all.each { |v| v.value = total_value}
        @all.clear
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
      resolve ->(o, args, c) { SumAll.new(c, o + args[:value]) }
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
      resolve ->(o, args, c) { SumAll.new(c, args[:value]) }
    end

    field :nestedSum, BoxedSum do
      argument :value, !types.Int
      resolve ->(o, args, c) { SumAll.new(c, args[:value]) }
    end

    field :listSum, types[BoxedSum] do
      argument :values, types[types.Int]
      resolve ->(o, args, c) { args[:values] }
    end
  end

  BoxedSchema = GraphQL::Schema.define do
    query(BoxedQuery)
    mutation(BoxedQuery)
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

    it "resolves mutation fields right away" do
      res = run_query %|
      mutation {
        a: sum(value: 2)
        b: sum(value: 4)
        c: sum(value: 6)
      }
      |

      assert_equal [2, 4, 6], res["data"].values
    end
  end

  describe "BoxMethodMap" do
    class SubBox < Box; end

    let(:map) { GraphQL::Execution::Boxed::BoxMethodMap.new }

    it "finds methods for classes and subclasses" do
      map.set(Box, :item)
      map.set(SumAll, :value)
      b = Box.new(1)
      sub_b = SubBox.new(2)
      s = SumAll.new({}, 3)
      assert_equal(:item, map.get(b))
      assert_equal(:item, map.get(sub_b))
      assert_equal(:value, map.get(s))
    end
  end
end
