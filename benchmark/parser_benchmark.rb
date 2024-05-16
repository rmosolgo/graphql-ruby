require "benchmark/ips"
require "graphql/c_parser"
require 'rust_graphql_parser'
require "memory_profiler"

BENCHMARK_PATH = File.expand_path("../", __FILE__)
BIG_QUERY_STRING = File.read(File.join(BENCHMARK_PATH, "big_query.graphql"))
BIG_QUERY = GraphQL.parse(BIG_QUERY_STRING)

def rust_parse(query)
  GraphQL.default_parser = RustGraphqlParserWrapper
  GraphQL.parse(BIG_QUERY_STRING)
end

def ruby_parse(query)
  GraphQL.default_parser = GraphQL::Language::Parser
  GraphQL.parse(BIG_QUERY_STRING)
end

def c_parse(query)
  GraphQL.default_parser = GraphQL::CParser
  GraphQL.parse(BIG_QUERY_STRING)
end

# Sanity check.
raise "output mismatch" unless rust_parse(BIG_QUERY) == ruby_parse(BIG_QUERY)

Benchmark.ips(time: 30) do |x|
  x.report("parsing - Rust") { rust_parse(BIG_QUERY) }
  x.report("parsing - C") { c_parse(BIG_QUERY) }
  x.report("parsing - Ruby") { ruby_parse(BIG_QUERY) }
  x.compare!
end
