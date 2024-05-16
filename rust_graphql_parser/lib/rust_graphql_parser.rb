# frozen_string_literal: true

require_relative "rust_graphql_parser/version"
require_relative "rust_graphql_parser/rust_graphql_parser"

module RustGraphqlParser
end

class RustGraphqlParserWrapper
  def self.parse(query_string, filename: nil, trace: GraphQL::Tracing::NullTrace, max_tokens: nil)
    trace.parse(query_string: query_string) do
      RustGraphqlParser.parse(query_string)
    end
  end
end
