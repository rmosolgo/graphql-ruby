# frozen_string_literal: true
require "dummy/schema"
require "benchmark/ips"
require 'ruby-prof'

module GraphQLBenchmark
  QUERY_STRING = GraphQL::Introspection::INTROSPECTION_QUERY
  DOCUMENT = GraphQL.parse(QUERY_STRING)
  SCHEMA = Dummy::Schema

  module_function
  def self.run(task)
    Benchmark.ips do |x|
      case task
      when "query"
        x.report("query") { SCHEMA.execute(document: DOCUMENT) }
      when "validate"
        x.report("validate") { SCHEMA.validate(DOCUMENT) }
      else
        raise("Unexpected task #{task}")
      end
      x.compare!
    end
  end

  def self.profile
    # Warm up any caches:
    SCHEMA.execute(document: DOCUMENT)

    result = RubyProf.profile do
      SCHEMA.execute(document: DOCUMENT)
    end

    printer = RubyProf::FlatPrinter.new(result)
    printer.print(STDOUT, {})
  end
end
