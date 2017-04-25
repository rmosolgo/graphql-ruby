# frozen_string_literal: true
module LazyHelpers
  class Wrapper
    def initialize(item = nil, &block)
      if block
        @block = block
      else
        @item = item
      end
    end

    def item
      if @block
        @item = @block.call()
        @block = nil
      end
      @item
    end
  end

  class SumAll
    attr_reader :own_value
    attr_accessor :value

    def initialize(ctx, own_value)
      @own_value = own_value
      all << self
    end

    def value
      @value ||= begin
        total_value = all.map(&:own_value).reduce(&:+)
        all.each { |v| v.value = total_value}
        all.clear
        total_value
      end
      @value
    end

    def all
      self.class.all
    end

    def self.all
      @all ||= []
    end
  end

  LazySum = GraphQL::ObjectType.define do
    name "LazySum"
    field :value, types.Int do
      resolve ->(o, a, c) { o == 13 ? nil : o }
    end
    field :nestedSum, !LazySum do
      argument :value, !types.Int
      resolve ->(o, args, c) {
        if args[:value] == 13
          Wrapper.new(nil)
        else
          SumAll.new(c, o + args[:value])
        end
      }
    end

    field :nullableNestedSum, LazySum do
      argument :value, types.Int
      resolve ->(o, args, c) {
        if args[:value] == 13
          Wrapper.new(nil)
        else
          SumAll.new(c, o + args[:value])
        end
      }
    end
  end

  LazyQuery = GraphQL::ObjectType.define do
    name "Query"
    field :int, !types.Int do
      argument :value, !types.Int
      argument :plus, types.Int, default_value: 0
      resolve ->(o, a, c) { Wrapper.new(a[:value] + a[:plus])}
    end

    field :nestedSum, !LazySum do
      argument :value, !types.Int
      resolve ->(o, args, c) { SumAll.new(c, args[:value]) }
    end

    field :nullableNestedSum, LazySum do
      argument :value, types.Int
      resolve ->(o, args, c) {
        if args[:value] == 13
          Wrapper.new { raise GraphQL::ExecutionError.new("13 is unlucky") }
        else
          SumAll.new(c, args[:value])
        end
      }
    end

    field :listSum, types[LazySum] do
      argument :values, types[types.Int]
      resolve ->(o, args, c) { args[:values] }
    end
  end

  module SumAllInstrumentation
    module_function

    def before_query(q)
      # TODO not threadsafe
      # This should use multiplex-level context
      SumAll.all.clear
    end

    def after_query(q)
    end
  end

  LazySchema = GraphQL::Schema.define do
    query(LazyQuery)
    mutation(LazyQuery)
    lazy_resolve(Wrapper, :item)
    lazy_resolve(SumAll, :value)
    instrument(:query, SumAllInstrumentation)
  end

  def run_query(query_str)
    LazySchema.execute(query_str)
  end
end
