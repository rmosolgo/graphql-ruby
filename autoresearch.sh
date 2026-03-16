#!/bin/bash
set -euo pipefail

# NOTE: benchmark/large_schema.graphql and benchmark/large_query.graphql
# are private files not included in the repo. Provide your own large schema
# and query files at those paths to run benchmarks.

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

# Build schemas with visibility profiles enabled (production-like)
CARD_SCHEMA = GraphQL::Schema.from_definition(File.read("benchmark/schema.graphql"))
CARD_SCHEMA.use(GraphQL::Schema::Visibility)

BIG_SCHEMA = GraphQL::Schema.from_definition(File.join("benchmark", "big_schema.graphql"))
BIG_SCHEMA.use(GraphQL::Schema::Visibility)

# Large real-world schema + query
LARGE_SCHEMA_DEF = GraphQL::Schema.from_definition(File.read("benchmark/large_schema.graphql"))
LARGE_SCHEMA_DEF.use(GraphQL::Schema::Visibility)
LARGE_SCHEMA_DEF.allow_legacy_invalid_return_type_conflicts(false)
LARGE_SCHEMA_DEF.did_you_mean(nil)

FIELDS_WILL_MERGE_SCHEMA = GraphQL::Schema.from_definition("type Query { hello: String }")
FIELDS_WILL_MERGE_SCHEMA.use(GraphQL::Schema::Visibility)

# Parse documents
ABSTRACT_FRAGMENTS = GraphQL.parse(File.read("benchmark/abstract_fragments.graphql"))
ABSTRACT_FRAGMENTS_2 = GraphQL.parse(File.read("benchmark/abstract_fragments_2.graphql"))
BIG_QUERY = GraphQL.parse(File.read("benchmark/big_query.graphql"))
LARGE_QUERY = GraphQL.parse(File.read("benchmark/large_query.graphql"))
FIELDS_WILL_MERGE_QUERY = GraphQL.parse("{ #{Array.new(5000, "hello").join(" ")} }")

# Suppress warnings during benchmark
$VERBOSE = nil

# Pre-create Query objects so we only benchmark static validation itself
# (not Query initialization, Profile creation, etc.)
def make_query(schema, doc)
  schema.query_class.new(schema, document: doc)
end

def make_validator(schema)
  GraphQL::StaticValidation::Validator.new(schema: schema)
end

Q_AF  = make_query(CARD_SCHEMA, ABSTRACT_FRAGMENTS)
Q_AF2 = make_query(CARD_SCHEMA, ABSTRACT_FRAGMENTS_2)
Q_BQ  = make_query(BIG_SCHEMA, BIG_QUERY)
Q_LQ  = make_query(LARGE_SCHEMA_DEF, LARGE_QUERY)
Q_FM  = make_query(FIELDS_WILL_MERGE_SCHEMA, FIELDS_WILL_MERGE_QUERY)

V_CARD     = make_validator(CARD_SCHEMA)
V_BIG      = make_validator(BIG_SCHEMA)
V_LARGE = make_validator(LARGE_SCHEMA_DEF)
V_FM       = make_validator(FIELDS_WILL_MERGE_SCHEMA)

max_errors = nil  # no limit

# Warmup
5.times do
  V_CARD.validate(Q_AF, max_errors: max_errors)
  V_CARD.validate(Q_AF2, max_errors: max_errors)
  V_BIG.validate(Q_BQ, max_errors: max_errors)
  V_LARGE.validate(Q_LQ, max_errors: max_errors)
  V_FM.validate(Q_FM, max_errors: max_errors)
end

n_small = 80
n_big = 50
n_large = 20
n_merge = 5
times = {}

t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
n_small.times { V_CARD.validate(Q_AF, max_errors: max_errors) }
times[:abstract_frags] = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t) / n_small * 1_000_000).round(1)

t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
n_small.times { V_CARD.validate(Q_AF2, max_errors: max_errors) }
times[:abstract_frags2] = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t) / n_small * 1_000_000).round(1)

t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
n_big.times { V_BIG.validate(Q_BQ, max_errors: max_errors) }
times[:big_query] = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t) / n_big * 1_000_000).round(1)

t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
n_large.times { V_LARGE.validate(Q_LQ, max_errors: max_errors) }
times[:large_query] = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t) / n_large * 1_000_000).round(1)

t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
n_merge.times { V_FM.validate(Q_FM, max_errors: max_errors) }
times[:fields_merge] = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t) / n_merge * 1_000_000).round(1)

# Primary metric: realistic workloads (abstract_frags + abstract_frags2 + big_query + large_query)
realistic = (times[:abstract_frags] + times[:abstract_frags2] + times[:big_query] + times[:large_query]).round(1)
puts "METRIC total_us=#{realistic}"
times.each { |k,v| puts "METRIC #{k}_us=#{v}" }
' 2>/dev/null
