# frozen_string_literal: true
# Before/after comparison of static validation performance.
# Pre-creates Query+Profile objects, measures only validation itself.
# Run with: bundle exec ruby -Ispec/support benchmark/compare_validation.rb
#
# NOTE: Requires private benchmark/checkout_schema.graphql and benchmark/large_query.graphql
# files not included in the repo.

RubyVM::YJIT.enable
ADD_WARDEN = false
TESTING_EXEC_NEXT = false
TESTING_METHOD = false
require "graphql"
require "jazz"
$VERBOSE = nil

# Build schemas with visibility profiles enabled (production-like)
CARD_SCHEMA = GraphQL::Schema.from_definition(File.read("benchmark/schema.graphql"))
CARD_SCHEMA.use(GraphQL::Schema::Visibility)

BIG_SCHEMA = GraphQL::Schema.from_definition(File.join("benchmark", "big_schema.graphql"))
BIG_SCHEMA.use(GraphQL::Schema::Visibility)

CHECKOUT_SCHEMA = GraphQL::Schema.from_definition(File.read("benchmark/checkout_schema.graphql"))
CHECKOUT_SCHEMA.use(GraphQL::Schema::Visibility)
CHECKOUT_SCHEMA.allow_legacy_invalid_return_type_conflicts(false)
CHECKOUT_SCHEMA.did_you_mean(nil)

FIELDS_WILL_MERGE_SCHEMA = GraphQL::Schema.from_definition("type Query { hello: String }")
FIELDS_WILL_MERGE_SCHEMA.use(GraphQL::Schema::Visibility)

# Parse documents
ABSTRACT_FRAGMENTS = GraphQL.parse(File.read("benchmark/abstract_fragments.graphql"))
ABSTRACT_FRAGMENTS_2 = GraphQL.parse(File.read("benchmark/abstract_fragments_2.graphql"))
BIG_QUERY = GraphQL.parse(File.read("benchmark/big_query.graphql"))
LARGE_QUERY = GraphQL.parse(File.read("benchmark/large_query.graphql"))
FIELDS_WILL_MERGE_QUERY = GraphQL.parse("{ #{Array.new(5000, "hello").join(" ")} }")

def make_query(schema, doc) = schema.query_class.new(schema, document: doc)
def make_validator(schema) = GraphQL::StaticValidation::Validator.new(schema: schema)

Q_AF  = make_query(CARD_SCHEMA, ABSTRACT_FRAGMENTS)
Q_AF2 = make_query(CARD_SCHEMA, ABSTRACT_FRAGMENTS_2)
Q_BQ  = make_query(BIG_SCHEMA, BIG_QUERY)
Q_LQ  = make_query(CHECKOUT_SCHEMA, LARGE_QUERY)
Q_FM  = make_query(FIELDS_WILL_MERGE_SCHEMA, FIELDS_WILL_MERGE_QUERY)

V_CARD     = make_validator(CARD_SCHEMA)
V_BIG      = make_validator(BIG_SCHEMA)
V_CHECKOUT = make_validator(CHECKOUT_SCHEMA)
V_FM       = make_validator(FIELDS_WILL_MERGE_SCHEMA)

# Warmup
8.times do
  V_CARD.validate(Q_AF)
  V_CARD.validate(Q_AF2)
  V_BIG.validate(Q_BQ)
  V_CHECKOUT.validate(Q_LQ)
  V_FM.validate(Q_FM)
end

def bench(label, validator, query, n)
  # 3 trials, take the median
  results = 3.times.map do
    t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    n.times { validator.validate(query) }
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t) / n * 1_000_000).round(1)
  end.sort
  median = results[1]
  puts "  %-20s %8.1f µs  (trials: %s)" % [label, median, results.map { |r| "%.1f" % r }.join(", ")]
  median
end

puts "Static Validation Benchmark (YJIT, Visibility Profiles, pure validation)"
puts "=" * 72
times = {}
times[:abstract_frags]  = bench("abstract_frags",  V_CARD, Q_AF, 100)
times[:abstract_frags2] = bench("abstract_frags2", V_CARD, Q_AF2, 100)
times[:big_query]       = bench("big_query",       V_BIG, Q_BQ, 60)
times[:large_query]     = bench("large_query",     V_CHECKOUT, Q_LQ, 30)
times[:fields_merge]    = bench("fields_merge",    V_FM, Q_FM, 8)

realistic = (times[:abstract_frags] + times[:abstract_frags2] + times[:big_query] + times[:large_query]).round(1)
puts "-" * 72
puts "  %-20s %8.1f µs" % ["TOTAL (realistic)", realistic]
puts "  %-20s %8.1f µs" % ["fields_merge", times[:fields_merge]]
