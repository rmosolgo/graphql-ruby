require "dummy/schema"
require "benchmark/ips"

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
end
