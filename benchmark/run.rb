# frozen_string_literal: true
require "graphql"
require "jazz"
require "benchmark/ips"
require "ruby-prof"
require "memory_profiler"

module GraphQLBenchmark
  QUERY_STRING = GraphQL::Introspection::INTROSPECTION_QUERY
  DOCUMENT = GraphQL.parse(QUERY_STRING)
  SCHEMA = Jazz::Schema

  BENCHMARK_PATH = File.expand_path("../", __FILE__)
  CARD_SCHEMA = GraphQL::Schema.from_definition(File.read(File.join(BENCHMARK_PATH, "schema.graphql")))
  ABSTRACT_FRAGMENTS = GraphQL.parse(File.read(File.join(BENCHMARK_PATH, "abstract_fragments.graphql")))
  ABSTRACT_FRAGMENTS_2 = GraphQL.parse(File.read(File.join(BENCHMARK_PATH, "abstract_fragments_2.graphql")))

  BIG_SCHEMA = GraphQL::Schema.from_definition(File.join(BENCHMARK_PATH, "big_schema.graphql"))
  BIG_QUERY = GraphQL.parse(File.read(File.join(BENCHMARK_PATH, "big_query.graphql")))

  module_function
  def self.run(task)
    Benchmark.ips do |x|
      case task
      when "query"
        x.report("query") { SCHEMA.execute(document: DOCUMENT) }
      when "validate"
        x.report("validate - introspection ") { CARD_SCHEMA.validate(DOCUMENT) }
        x.report("validate - abstract fragments") { CARD_SCHEMA.validate(ABSTRACT_FRAGMENTS) }
        x.report("validate - abstract fragments 2") { CARD_SCHEMA.validate(ABSTRACT_FRAGMENTS_2) }
        x.report("validate - big query") { BIG_SCHEMA.validate(BIG_QUERY) }
      else
        raise("Unexpected task #{task}")
      end
    end
  end

  def self.profile
    # Warm up any caches:
    SCHEMA.execute(document: DOCUMENT)
    # CARD_SCHEMA.validate(ABSTRACT_FRAGMENTS)
    res = nil
    result = RubyProf.profile do
      # CARD_SCHEMA.validate(ABSTRACT_FRAGMENTS)
      res = SCHEMA.execute(document: DOCUMENT)
    end
    # printer = RubyProf::FlatPrinter.new(result)
    printer = RubyProf::GraphHtmlPrinter.new(result)
    # printer = RubyProf::FlatPrinterWithLineNumbers.new(result)

    printer.print(STDOUT, {})
  end
end
