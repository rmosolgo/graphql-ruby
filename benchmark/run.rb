# frozen_string_literal: true
require "dummy/schema"
require "benchmark/ips"
require 'ruby-prof'

module GraphQLBenchmark
  QUERY_STRING = GraphQL::Introspection::INTROSPECTION_QUERY
  DOCUMENT = GraphQL.parse(QUERY_STRING)
  SCHEMA = Dummy::Schema

  BENCHMARK_PATH = File.expand_path("../", __FILE__)
  CARD_SCHEMA = GraphQL::Schema.from_definition(File.read(File.join(BENCHMARK_PATH, "schema.graphql")))
  ABSTRACT_FRAGMENTS = GraphQL.parse(File.read(File.join(BENCHMARK_PATH, "abstract_fragments.graphql")))

  module_function
  def self.run(task)

    Benchmark.ips do |x|
      case task
      when "query"
        x.report("query") { SCHEMA.execute(document: DOCUMENT) }
      when "validate"
        x.report("validate - introspection ") { CARD_SCHEMA.validate(DOCUMENT) }
        x.report("validate - abstract fragments") { CARD_SCHEMA.validate(ABSTRACT_FRAGMENTS) }
      else
        raise("Unexpected task #{task}")
      end
      x.compare!
    end
  end

  def self.profile
    # Warm up any caches:
    SCHEMA.execute(document: DOCUMENT)
    CARD_SCHEMA.validate(ABSTRACT_FRAGMENTS)

    result = RubyProf.profile do
      CARD_SCHEMA.validate(ABSTRACT_FRAGMENTS)
      # SCHEMA.execute(document: DOCUMENT)
    end

    printer = RubyProf::FlatPrinter.new(result)
    # printer = RubyProf::GraphHtmlPrinter.new(result)
    # printer = RubyProf::FlatPrinterWithLineNumbers.new(result)

    printer.print(STDOUT, {})
  end
end
