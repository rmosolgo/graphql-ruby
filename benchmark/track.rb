# frozen_string_literal: true
require_relative "./run"
require "benchmark/memory"

# These benchmarks are run on every push to master (see .github/workflows/benchmarks.yaml),
# and the results are charted at https://rmosolgo.github.io/graphql-ruby-benchmarks/dev/bench/
#
# Each label is the key for that benchmark's history, so renaming one starts a new chart.
module GraphQLBenchmark
  module Track
    # Execution benchmarks use GraphQL::Execution::Next
    EXECUTE_SCHEMA = Class.new(SCHEMA) { use(GraphQL::Execution::Next) }
    SMALL_QUERY_ON_LARGE_SCHEMA = Class.new(SILLY_LARGE_SCHEMA) { use(GraphQL::Execution::Next) }

    SCENARIOS = {
      "parse - introspection" => -> { GraphQL.parse(QUERY_STRING) },
      "parse - big query" => -> { GraphQL.parse(BIG_QUERY_STRING) },
      "validate - abstract fragments" => -> { CARD_SCHEMA.validate(ABSTRACT_FRAGMENTS) },
      "validate - big query" => -> { BIG_SCHEMA.validate(BIG_QUERY) },
      "validate - fields will merge" => -> { FIELDS_WILL_MERGE_SCHEMA.validate(FIELDS_WILL_MERGE_QUERY) },
      "execute - introspection" => -> { EXECUTE_SCHEMA.execute_next(document: DOCUMENT) },
      "execute - small query on large schema" => -> { SMALL_QUERY_ON_LARGE_SCHEMA.execute_next("{ __typename }") },
      "execute - large result" => -> { ProfileLargeResult::Schema.execute_next(document: ProfileLargeResult::ALL_FIELDS) },
    }

    module_function

    def runtime
      Benchmark.ips do |x|
        SCENARIOS.each do |label, scenario|
          x.report(label, &scenario)
        end
      end
    end

    def memory
      # Warm up lazily-built caches so that only steady-state allocations are measured
      SCENARIOS.each_value(&:call)
      Benchmark.memory do |x|
        SCENARIOS.each do |label, scenario|
          x.report(label, &scenario)
        end
      end
    end

    def schema_memory
      # Build and discard one schema first, so that one-time allocations
      # (for example, Ruby's method caches) aren't counted against the measured one
      GraphQLBenchmark.build_large_schema_with_mutations
      GC.start
      retained_schema = nil
      Benchmark.memory do |x|
        x.report("build large schema") {
          retained_schema = GraphQLBenchmark.build_large_schema_with_mutations
        }
      end
      retained_schema
    end
  end
end
