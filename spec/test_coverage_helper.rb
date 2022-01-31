# frozen_string_literal: true
puts "Starting Code Coverage"
require 'simplecov'
SimpleCov.at_exit do
  SimpleCov.result.format!
end

SimpleCov.start do
  enable_coverage :branch
  primary_coverage :branch
  add_filter %r{^/spec/}
  add_filter %r{^/benchmark/}
  add_group "Schema Definition", [
    "lib/graphql/schema",
    "lib/graphql/types",
    "lib/graphql/type_kinds.rb",
    "lib/graphql/rake_task",
    "lib/graphql/rubocop",
    "lib/graphql/invalid_name_error.rb",
    "lib/graphql/name_validator.rb",
  ]
  add_group "Language", [
    "lib/graphql/language",
    "lib/graphql/parse_error.rb",
    "lib/graphql/railtie.rb",
  ]
  add_group "Dataloader", ["lib/graphql/dataloader"]
  add_group "Pagination", ["lib/graphql/pagination"]
  add_group "Introspection", ["lib/graphql/introspection"]
  add_group "Execution", [
    "lib/graphql/static_validation",
    "lib/graphql/analysis",
    "lib/graphql/analysis_error.rb",
    "lib/graphql/backtrace",
    "lib/graphql/errors",
    "lib/graphql/execution",
    "lib/graphql/query",
    "lib/graphql/relay",
    "lib/graphql/tracing",
    "lib/graphql/runtime_type_error.rb",
    "lib/graphql/load_application_object_failed_error.rb",
    "lib/graphql/filter.rb",
    "lib/graphql/dig.rb",
    "lib/graphql/unauthorized_error.rb",
    "lib/graphql/unauthorized_field_error.rb",
    "lib/graphql/invalid_null_error.rb",
    "lib/graphql/coercion_error.rb",
    "lib/graphql/integer_encoding_error.rb",
    "lib/graphql/integer_decoding_error.rb",
    "lib/graphql/string_encoding_error.rb",
    "lib/graphql/runtime_type_error.rb",
    "lib/graphql/unresolved_type_error.rb",
  ]
  add_group "Subscriptions", ["lib/graphql/subscriptions"]
  add_group "Generators", "lib/generators"

  formatter SimpleCov::Formatter::HTMLFormatter
end
