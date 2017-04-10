# frozen_string_literal: true
require "delegate"
require "json"
require "set"
require "singleton"
require "forwardable"

module GraphQL
  class Error < StandardError
  end

  class ParseError < Error
    attr_reader :line, :col, :query
    def initialize(message, line, col, query)
      super(message)
      @line = line
      @col = col
      @query = query
    end

    def to_h
      locations = line ? [{ "line" => line, "column" => col }] : []
      {
        "message" => message,
        "locations" => locations,
      }
    end
  end

  # Turn a query string into an AST
  # @param query_string [String] a GraphQL query string
  # @return [GraphQL::Language::Nodes::Document]
  def self.parse(query_string)
    parse_with_racc(query_string)
  end

  def self.parse_with_racc(string)
    GraphQL::Language::Parser.parse(string)
  end

  # @return [Array<GraphQL::Language::Token>]
  def self.scan(query_string)
    scan_with_ragel(query_string)
  end

  def self.scan_with_ragel(query_string)
    GraphQL::Language::Lexer.tokenize(query_string)
  end
end

# Order matters for these:

require "graphql/execution_error"
require "graphql/define"
require "graphql/base_type"
require "graphql/object_type"

require "graphql/enum_type"
require "graphql/input_object_type"
require "graphql/interface_type"
require "graphql/list_type"
require "graphql/non_null_type"
require "graphql/union_type"

require "graphql/argument"
require "graphql/field"
require "graphql/type_kinds"

require "graphql/scalar_type"
require "graphql/boolean_type"
require "graphql/float_type"
require "graphql/id_type"
require "graphql/int_type"
require "graphql/string_type"
require "graphql/directive"

require "graphql/introspection"
require "graphql/language"
require "graphql/analysis"
require "graphql/execution"
require "graphql/schema"
require "graphql/schema/loader"
require "graphql/schema/printer"

require "graphql/analysis_error"
require "graphql/runtime_type_error"
require "graphql/invalid_null_error"
require "graphql/unresolved_type_error"
require "graphql/string_encoding_error"
require "graphql/query"
require "graphql/internal_representation"
require "graphql/static_validation"
require "graphql/version"
require "graphql/relay"
require "graphql/compatibility"
require "graphql/function"
