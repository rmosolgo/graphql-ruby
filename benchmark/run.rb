# frozen_string_literal: true
require "graphql"
require "jazz"
require "benchmark/ips"
require "stackprof"
require "memory_profiler"
require "graphql/batch"

module GraphQLBenchmark
  QUERY_STRING = GraphQL::Introspection::INTROSPECTION_QUERY
  DOCUMENT = GraphQL.parse(QUERY_STRING)
  SCHEMA = Jazz::Schema

  BENCHMARK_PATH = File.expand_path("../", __FILE__)
  CARD_SCHEMA = GraphQL::Schema.from_definition(File.read(File.join(BENCHMARK_PATH, "schema.graphql")))
  ABSTRACT_FRAGMENTS = GraphQL.parse(File.read(File.join(BENCHMARK_PATH, "abstract_fragments.graphql")))
  ABSTRACT_FRAGMENTS_2_QUERY_STRING = File.read(File.join(BENCHMARK_PATH, "abstract_fragments_2.graphql"))
  ABSTRACT_FRAGMENTS_2 = GraphQL.parse(ABSTRACT_FRAGMENTS_2_QUERY_STRING)

  BIG_SCHEMA = GraphQL::Schema.from_definition(File.join(BENCHMARK_PATH, "big_schema.graphql"))
  BIG_QUERY_STRING = File.read(File.join(BENCHMARK_PATH, "big_query.graphql"))
  BIG_QUERY = GraphQL.parse(BIG_QUERY_STRING)

  FIELDS_WILL_MERGE_SCHEMA = GraphQL::Schema.from_definition("type Query { hello: String }")
  FIELDS_WILL_MERGE_QUERY = GraphQL.parse("{ #{Array.new(5000, "hello").join(" ")} }")

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
        x.report("validate - fields will merge") { FIELDS_WILL_MERGE_SCHEMA.validate(FIELDS_WILL_MERGE_QUERY) }
      when "parse"
        x.report("scan - introspection") { GraphQL.scan(QUERY_STRING) }
        x.report("parse - introspection") { GraphQL.parse(QUERY_STRING) }
        x.report("scan - fragments") { GraphQL.scan(ABSTRACT_FRAGMENTS_2_QUERY_STRING) }
        x.report("parse - fragments") { GraphQL.parse(ABSTRACT_FRAGMENTS_2_QUERY_STRING) }
        x.report("scan - big query") { GraphQL.scan(BIG_QUERY_STRING) }
        x.report("parse - big query") { GraphQL.parse(BIG_QUERY_STRING) }
      else
        raise("Unexpected task #{task}")
      end
    end
  end

  def self.validate_memory
    FIELDS_WILL_MERGE_SCHEMA.validate(FIELDS_WILL_MERGE_QUERY)

    report = MemoryProfiler.report do
      FIELDS_WILL_MERGE_SCHEMA.validate(FIELDS_WILL_MERGE_QUERY)
      nil
    end

    report.pretty_print
  end

  def self.profile
    # Warm up any caches:
    SCHEMA.execute(document: DOCUMENT)
    # CARD_SCHEMA.validate(ABSTRACT_FRAGMENTS)
    res = nil
    result = StackProf.run(mode: :wall) do
      # CARD_SCHEMA.validate(ABSTRACT_FRAGMENTS)
      res = SCHEMA.execute(document: DOCUMENT)
    end
    StackProf::Report.new(result).print_text
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

    result = StackProf.run(mode: :wall) do
      schema.execute(document: document)
    end
    StackProf::Report.new(result).print_text

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
      use GraphQL::Dataloader
    end

    ALL_FIELDS = GraphQL.parse <<-GRAPHQL
      query($skip: Boolean = false) {
        foos {
          id @skip(if: $skip)
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

  def self.profile_batch_loaders
    require_relative "./batch_loading"
    include BatchLoading

    document = GraphQL.parse <<-GRAPHQL
    {
      braves: team(name: "Braves") { ...TeamFields }
      bulls: team(name: "Bulls") { ...TeamFields }
    }

    fragment TeamFields on Team {
      players {
        team {
          players {
            team {
              name
            }
          }
        }
      }
    }
    GRAPHQL
    batch_result = GraphQLBatchSchema.execute(document: document).to_h
    dataloader_result = GraphQLDataloaderSchema.execute(document: document).to_h
    no_batch_result = GraphQLNoBatchingSchema.execute(document: document).to_h

    results = [batch_result, dataloader_result, no_batch_result].uniq
    if results.size > 1
      puts "Batch result:"
      pp batch_result
      puts "Dataloader result:"
      pp dataloader_result
      puts "No-batch result:"
      pp no_batch_result
      raise "Got different results -- fix implementation before benchmarking."
    end

    Benchmark.ips do |x|
      x.report("GraphQL::Batch") { GraphQLBatchSchema.execute(document: document) }
      x.report("GraphQL::Dataloader") { GraphQLDataloaderSchema.execute(document: document) }
      x.report("No Batching") { GraphQLNoBatchingSchema.execute(document: document) }

      x.compare!
    end

    puts "========== GraphQL-Batch Memory =============="
    report = MemoryProfiler.report do
      GraphQLBatchSchema.execute(document: document)
    end

    report.pretty_print

    puts "========== Dataloader Memory ================="
    report = MemoryProfiler.report do
      GraphQLDataloaderSchema.execute(document: document)
    end

    report.pretty_print

    puts "========== No Batch Memory =============="
    report = MemoryProfiler.report do
      GraphQLNoBatchingSchema.execute(document: document)
    end

    report.pretty_print
  end

  def self.profile_schema_memory_footprint
    schema = nil
    report = MemoryProfiler.report do
      query_type = Class.new(GraphQL::Schema::Object) do
        graphql_name "Query"
        100.times do |i|
          type = Class.new(GraphQL::Schema::Object) do
            graphql_name "Object#{i}"
            field :f, Integer
          end
          field "f#{i}", type
        end
      end

      thing_type = Class.new(GraphQL::Schema::Object) do
        graphql_name "Thing"
        field :name, String
      end

      mutation_type = Class.new(GraphQL::Schema::Object) do
        graphql_name "Mutation"
        100.times do |i|
          mutation_class = Class.new(GraphQL::Schema::RelayClassicMutation) do
            graphql_name "Do#{i}"
            argument :id, "ID"
            field :thing, thing_type
            field :things, thing_type.connection_type
          end
          field "f#{i}", mutation: mutation_class
        end
      end

      schema = Class.new(GraphQL::Schema) do
        query(query_type)
        mutation(mutation_type)
      end
    end

    report.pretty_print
  end

  class StackDepthSchema < GraphQL::Schema
    class Thing < GraphQL::Schema::Object
      field :thing, self do
        argument :lazy, Boolean, default_value: false
      end

      def thing(lazy:)
        if lazy
          -> { :something }
        else
          :something
        end
      end

      field :stack_trace_depth, Integer do
        argument :lazy, Boolean, default_value: false
      end

      def stack_trace_depth(lazy:)
        get_depth = -> {
          graphql_caller = caller.select { |c| c.include?("graphql") }
          graphql_caller.size
        }

        if lazy
          get_depth
        else
          get_depth.call
        end
      end
    end

    class Query < GraphQL::Schema::Object
      field :thing, Thing

      def thing
        :something
      end
    end

    query(Query)
    lazy_resolve(Proc, :call)
  end

  def self.profile_stack_depth
    query_str = <<-GRAPHQL
    query($lazyThing: Boolean!, $lazyStackTrace: Boolean!) {
      thing {
        thing(lazy: $lazyThing) {
          thing(lazy: $lazyThing) {
            thing(lazy: $lazyThing) {
              thing(lazy: $lazyThing) {
                stackTraceDepth(lazy: $lazyStackTrace)
              }
            }
          }
        }
      }
    }
    GRAPHQL

    eager_res = StackDepthSchema.execute(query_str, variables: { lazyThing: false, lazyStackTrace: false })
    lazy_res = StackDepthSchema.execute(query_str, variables: { lazyThing: true, lazyStackTrace: false })
    very_lazy_res = StackDepthSchema.execute(query_str, variables: { lazyThing: true, lazyStackTrace: true })
    get_depth = ->(result) { result["data"]["thing"]["thing"]["thing"]["thing"]["thing"]["stackTraceDepth"] }

    puts <<~RESULT
    Result         Depth
    ---------------------
    Eager          #{get_depth.call(eager_res)}
    Lazy           #{get_depth.call(lazy_res)}
    Very Lazy      #{get_depth.call(very_lazy_res)}
    RESULT
  end
end
