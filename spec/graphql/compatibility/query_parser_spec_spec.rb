require "spec_helper"

BuiltInParserSuite = GraphQL::Compatibility::QueryParserSpec.build_suite do |query_string|
  GraphQL::Language::Parser.parse(query_string)
end
