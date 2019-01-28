# frozen_string_literal: true
TESTING_INTERPRETER = true
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
    # printer = RubyProf::GraphHtmlPrinter.new(result)
    printer = RubyProf::FlatPrinterWithLineNumbers.new(result)

    printer.print(STDOUT, {})
  end

  # Adapted from https://github.com/rmosolgo/graphql-ruby/issues/861
  def self.profile_large_result
    schema = ProfileLargeResult::Schema
    document = ProfileLargeResult::ALL_FIELDS
    Benchmark.ips do |x|
      x.report("Querying for #{ProfileLargeResult::DATA.size} objects") {
        schema.execute(document: document)
      }
    end

    result = RubyProf.profile do
      schema.execute(document: document)
    end
    printer = RubyProf::FlatPrinter.new(result)
    # printer = RubyProf::GraphHtmlPrinter.new(result)
    # printer = RubyProf::FlatPrinterWithLineNumbers.new(result)
    printer.print(STDOUT, {})

    report = MemoryProfiler.report do
      schema.execute(document: document)
    end

    report.pretty_print
  end

  module ProfileLargeResult
    DATA = 1000.times.map {
      {
        id:             SecureRandom.uuid,
        int1:           SecureRandom.random_number(100000),
        int2:           SecureRandom.random_number(100000),
        string1:        SecureRandom.base64,
        string2:        SecureRandom.base64,
        boolean1:       SecureRandom.random_number(1) == 0,
        boolean2:       SecureRandom.random_number(1) == 0,
        int_array:      10.times.map { SecureRandom.random_number(100000) },
        string_array:   10.times.map { SecureRandom.base64 },
        boolean_array:  10.times.map { SecureRandom.random_number(1) == 0 },
      }
    }


    class FooType < GraphQL::Schema::Object
      field :id, ID, null: false
      field :int1, Integer, null: false
      field :int2, Integer, null: false
      field :string1, String, null: false
      field :string2, String, null: false
      field :boolean1, Boolean, null: false
      field :boolean2, Boolean, null: false
      field :string_array, [String], null: false
      field :int_array, [Integer], null: false
      field :boolean_array, [Boolean], null: false
    end

    class QueryType < GraphQL::Schema::Object
      description "Query root of the system"
      field :foos, [FooType], null: false, description: "Return a list of Foo objects"
      def foos
        DATA
      end
    end

    class Schema < GraphQL::Schema
      query QueryType
      if TESTING_INTERPRETER
        use GraphQL::Execution::Interpreter
      end
    end

    ALL_FIELDS = GraphQL.parse <<-GRAPHQL
      {
        foos {
          id
          int1
          int2
          string1
          string2
          boolean1
          boolean2
          stringArray
          intArray
          booleanArray
        }
      }
    GRAPHQL
  end
end
