# frozen_string_literal: true
require "dummy/schema"
require "benchmark/ips"
require 'ruby-prof'
require 'memory_profiler'

module GraphQLBenchmark
  QUERY_STRING = GraphQL::Introspection::INTROSPECTION_QUERY
  DOCUMENT = GraphQL.parse(QUERY_STRING)
  SCHEMA = Dummy::Schema

  BENCHMARK_PATH = File.expand_path("../", __FILE__)
  CARD_SCHEMA = GraphQL::Schema.from_definition(File.read(File.join(BENCHMARK_PATH, "schema.graphql")))
  HACKERONE_SCHEMA = GraphQL::Schema.from_definition(
    File.read(
      File.join(BENCHMARK_PATH, "hackerone_schema.graphql")
    )
  )

  HACKERONE_QUERY = GraphQL.parse(File.read(File.join(BENCHMARK_PATH, "hackerone_query.graphql")))

  ABSTRACT_FRAGMENTS = GraphQL.parse(File.read(File.join(BENCHMARK_PATH, "abstract_fragments.graphql")))
  ABSTRACT_FRAGMENTS_2 = GraphQL.parse(File.read(File.join(BENCHMARK_PATH, "abstract_fragments_2.graphql")))

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
        x.report("validate - hackerone query") { HACKERONE_SCHEMA.validate(HACKERONE_QUERY) }
      else
        raise("Unexpected task #{task}")
      end
    end
  end

  def self.profile
    profile_block do
      SCHEMA.execute(document: DOCUMENT)
    end
  end

  def self.profile_validation
    profile_block do
      HACKERONE_SCHEMA.validate(HACKERONE_QUERY)
    end
  end

  def self.profile_block
    # Warm up any caches:
    yield

    result = RubyProf.profile do
      yield
    end

    # Print a flat profile to text
    File.open "h1-before-graph.html", 'w' do |file|
      RubyProf::GraphHtmlPrinter.new(result).print(file)
    end

    File.open "h1-before-flat.txt", 'w' do |file|
      # RubyProf::FlatPrinter.new(result).print(file)
      RubyProf::FlatPrinterWithLineNumbers.new(result).print(file)
    end

    File.open "h1-before-stack.html", 'w' do |file|
      RubyProf::CallStackPrinter.new(result).print(file)
    end

    printer = RubyProf::FlatPrinter.new(result)
    html_printer = RubyProf::GraphHtmlPrinter.new(result)
    File.open("h1-before-profile.html", "wb") { |f| html_printer.print(f, {}) }
    # printer = RubyProf::FlatPrinterWithLineNumbers.new(result)

    printer.print(STDOUT, {})

    MemoryProfiler.report { yield }.pretty_print
  end
end
