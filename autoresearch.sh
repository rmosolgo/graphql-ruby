#!/bin/bash
set -euo pipefail

# Quick syntax check on key files
ruby -c lib/graphql/static_validation/rules/fields_will_merge.rb > /dev/null 2>&1
ruby -c lib/graphql/static_validation/base_visitor.rb > /dev/null 2>&1
ruby -c lib/graphql/static_validation/validator.rb > /dev/null 2>&1

exec bundle exec ruby -Ispec/support -e '
RubyVM::YJIT.enable
ADD_WARDEN = false
TESTING_EXEC_NEXT = false
TESTING_METHOD = false
require "graphql"
require "jazz"

QUERY_STRING = GraphQL::Introspection::INTROSPECTION_QUERY
DOCUMENT = GraphQL.parse(QUERY_STRING)

# Build schemas with visibility profiles enabled (production-like)
CARD_SCHEMA = GraphQL::Schema.from_definition(File.read("benchmark/schema.graphql"))
CARD_SCHEMA.use(GraphQL::Schema::Visibility)

BIG_SCHEMA = GraphQL::Schema.from_definition(File.join("benchmark", "big_schema.graphql"))
BIG_SCHEMA.use(GraphQL::Schema::Visibility)

# Real-world checkout schema + large query
CHECKOUT_SCHEMA = GraphQL::Schema.from_definition(File.read("benchmark/checkout_schema.graphql"))
CHECKOUT_SCHEMA.use(GraphQL::Schema::Visibility)
# Suppress return type conflict warnings (they spam logger.warn)
CHECKOUT_SCHEMA.allow_legacy_invalid_return_type_conflicts(false)
LARGE_QUERY = GraphQL.parse(File.read("benchmark/large_query.graphql"))

ABSTRACT_FRAGMENTS = GraphQL.parse(File.read("benchmark/abstract_fragments.graphql"))
ABSTRACT_FRAGMENTS_2 = GraphQL.parse(File.read("benchmark/abstract_fragments_2.graphql"))
BIG_QUERY = GraphQL.parse(File.read("benchmark/big_query.graphql"))

FIELDS_WILL_MERGE_SCHEMA = GraphQL::Schema.from_definition("type Query { hello: String }")
FIELDS_WILL_MERGE_SCHEMA.use(GraphQL::Schema::Visibility)
FIELDS_WILL_MERGE_QUERY = GraphQL.parse("{ #{Array.new(5000, "hello").join(" ")} }")

# Suppress warnings during benchmark
$VERBOSE = nil
require "logger"

# Warmup
5.times do
  CARD_SCHEMA.validate(DOCUMENT)
  CARD_SCHEMA.validate(ABSTRACT_FRAGMENTS)
  CARD_SCHEMA.validate(ABSTRACT_FRAGMENTS_2)
  BIG_SCHEMA.validate(BIG_QUERY)
  CHECKOUT_SCHEMA.validate(LARGE_QUERY)
  FIELDS_WILL_MERGE_SCHEMA.validate(FIELDS_WILL_MERGE_QUERY)
end

n_small = 50
n_big = 30
n_large = 10
n_merge = 3
times = {}

t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
n_small.times { CARD_SCHEMA.validate(ABSTRACT_FRAGMENTS) }
times[:abstract_frags] = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t) / n_small * 1_000_000).round(1)

t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
n_small.times { CARD_SCHEMA.validate(ABSTRACT_FRAGMENTS_2) }
times[:abstract_frags2] = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t) / n_small * 1_000_000).round(1)

t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
n_big.times { BIG_SCHEMA.validate(BIG_QUERY) }
times[:big_query] = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t) / n_big * 1_000_000).round(1)

t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
n_large.times { CHECKOUT_SCHEMA.validate(LARGE_QUERY) }
times[:large_query] = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t) / n_large * 1_000_000).round(1)

t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
n_merge.times { FIELDS_WILL_MERGE_SCHEMA.validate(FIELDS_WILL_MERGE_QUERY) }
times[:fields_merge] = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t) / n_merge * 1_000_000).round(1)

# Primary metric: realistic workloads (abstract_frags + abstract_frags2 + big_query + large_query)
realistic = (times[:abstract_frags] + times[:abstract_frags2] + times[:big_query] + times[:large_query]).round(1)
puts "METRIC total_us=#{realistic}"
times.each { |k,v| puts "METRIC #{k}_us=#{v}" }
' 2>/dev/null
