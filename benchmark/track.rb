# frozen_string_literal: true
require_relative "./run"
require "benchmark/memory"

# These benchmarks are run on every push to master (see .github/workflows/benchmarks.yaml),
# and the results are charted at https://rmosolgo.github.io/graphql-ruby-benchmarks/dev/bench/
#
# Each label is the key for that benchmark's history, so renaming one starts a new chart.
module GraphQLBenchmark
  module Track
    SMALL_QUERY_ON_LARGE_SCHEMA = Class.new(SILLY_LARGE_SCHEMA)

    SCENARIOS = {
      "parse - introspection" => -> { GraphQL.parse(QUERY_STRING) },
      "parse - big query" => -> { GraphQL.parse(BIG_QUERY_STRING) },
      "validate - abstract fragments" => -> { CARD_SCHEMA.validate(ABSTRACT_FRAGMENTS) },
      "validate - big query" => -> { BIG_SCHEMA.validate(BIG_QUERY) },
      "validate - fields will merge" => -> { FIELDS_WILL_MERGE_SCHEMA.validate(FIELDS_WILL_MERGE_QUERY) },
      "execute - introspection" => -> { SCHEMA.execute(document: DOCUMENT) },
      "execute - small query on large schema" => -> { SMALL_QUERY_ON_LARGE_SCHEMA.execute("{ __typename }") },
      "execute - large result" => -> { ProfileLargeResult::Schema.execute(document: ProfileLargeResult::ALL_FIELDS) },
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
  end
end
