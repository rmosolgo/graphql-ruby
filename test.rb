# Add the GraphQL-Ruby library in my local directory
$LOAD_PATH << "./lib"
require "graphql"
require "benchmark/ips"

class NestedMetric < GraphQL::Schema::Object
  class << self
    attr_accessor :object_count_baseline
  end

  field :metric, NestedMetric, null: false,
    description: "A way to build up a large query"

  def metric
    # A non-nil object to continue execution
    :metric
  end

  field :backtrace_size, Integer, null: false,
    description: "The number of lines in the backtrace"

  def backtrace_size
    caller.size
  end

  field :object_count, Integer, null: false,
    description: "The number of live objects in Ruby's heap"

  def object_count
    # Make a GC pass
    GC.start
    # Count how many objects are alive in the heap
    GC.stat[:heap_live_slots] - self.class.object_count_baseline
  end

  field :object_count_baseline, Integer, null: false,
    description: "The number of live objects in Ruby's heap"

  def object_count_baseline
    self.class.object_count_baseline
  end
end

class Query < GraphQL::Schema::Object
  field :metric, NestedMetric, null: false
  def metric
    # A non-nil object to continue execution
    :metric
  end
end

class Schema < GraphQL::Schema
  use GraphQL::Execution::Interpreter
  query(Query)
end

# Build out some initial caches
Schema.graphql_definition
# Get a baseline object count
GC.start
starting_objects = GC.stat[:heap_live_slots]
NestedMetric.object_count_baseline = starting_objects

query_str = <<-GRAPHQL
{
  metric {
    metric {
      metric {
        metric {
          metric {
            metric {
              metric {
                metric {
                  metric {
                    metric {
                      metric {
                        metric {
                          metric {
                            metric {
                              metric {
                                metric {
                                  metric {
                                    metric {
                                      backtraceSize
                                      objectCount
                                      objectCountBaseline
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
GRAPHQL

# For posterity
puts `git rev-parse HEAD`
res = Schema.execute(query_str)

data = res["data"]
# Find the leaf values:
while data.key?("metric")
  data = data["metric"]
end
# Print the leaf values
p data

Benchmark.ips do |x|
  x.report { Schema.execute(query_str) }
  x.compare!
end
