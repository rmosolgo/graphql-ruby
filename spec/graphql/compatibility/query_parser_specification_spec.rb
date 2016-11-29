# frozen_string_literal: true
require "spec_helper"

BuiltInQueryParserSuite = GraphQL::Compatibility::QueryParserSpecification.build_suite do |query_string|
  GraphQL::Language::Parser.parse(query_string)
end
