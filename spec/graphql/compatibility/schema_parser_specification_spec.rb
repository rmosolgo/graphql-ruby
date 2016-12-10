# frozen_string_literal: true
require "spec_helper"

BuiltInSchemaParserSuite = GraphQL::Compatibility::SchemaParserSpecification.build_suite do |query_string|
  GraphQL::Language::Parser.parse(query_string)
end
