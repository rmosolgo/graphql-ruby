require "spec_helper"

BuiltInParserSuite = GraphQL::Compatibility::SchemaParserSpec.build_suite do |query_string|
  GraphQL::Language::Parser.parse(query_string)
end
