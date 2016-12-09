# frozen_string_literal: true
require "graphql/language/definition_slice"
require "graphql/language/generation"
require "graphql/language/lexer"
require "graphql/language/nodes"
require "graphql/language/parser"
require "graphql/language/token"
require "graphql/language/visitor"
require "graphql/language/comments"

module GraphQL
  module Language
    # @api private
    def self.serialize(value)
      JSON.generate(value, quirks_mode: true)
    end
  end
end
