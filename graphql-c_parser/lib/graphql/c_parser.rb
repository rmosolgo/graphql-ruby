# frozen_string_literal: true

require "graphql"
require "graphql/c_parser/version"
require "graphql/graphql_c_parser_ext"

module GraphQL
  module CParser
  end

  def self.scan_with_c(graphql_string)
    GraphQL::Language::CLexer.tokenize(graphql_string)
  end
end
