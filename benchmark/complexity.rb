# frozen_string_literal: true
require "bundler/setup"
require "graphql"
require "benchmark"
require "benchmark/ips"

CONCRETE_TYPES_COUNT = 5_000
QUERY = "{ myObject { ... on MyInterface { name } } }"

module MyInterface
  include GraphQL::Schema::Interface

  field :name, String, null: false
end

CONCRETE_TYPES = (1..CONCRETE_TYPES_COUNT).map do |i|
  Class.new(GraphQL::Schema::Object) do
    implements MyInterface

    graphql_name "MyConcreteObject#{i}"

    field :name, String, null: false
  end
end

class MyQueryType < GraphQL::Schema::Object
  field :my_object, MyInterface, null: false

  def my_object
    { name: "Gabriel Sobrinho" }
  end
end

class MySchema < GraphQL::Schema
  query MyQueryType

  orphan_types CONCRETE_TYPES

  max_complexity 1_000

  complexity_cost_calculation_mode :compare

  def self.resolve_type(_type, _obj, _ctx)
    CONCRETE_TYPES[0]
  end
end

# Warmup
errors = MySchema.validate(QUERY)
warn errors.inspect if errors.any?

Benchmark.ips do |x|
  x.report("Running query with complexity analysis") do
    MySchema.execute(QUERY)
  end
end
