# frozen_string_literal: true
require "graphql/language/block_string"
require "graphql/language/printer"
require "graphql/language/definition_slice"
require "graphql/language/document_from_schema_definition"
require "graphql/language/generation"
require "graphql/language/lexer"
require "graphql/language/nodes"
require "graphql/language/parser"
require "graphql/language/token"
require "graphql/language/visitor"

module GraphQL
  module Language
    # @api private
    def self.serialize(value)
      if value.is_a?(Hash)
        serialized_hash = value.map do |k, v|
          "#{k}:#{serialize v}"
        end.join(",")

        "{#{serialized_hash}}"
      elsif value.is_a?(Array)
        serialized_array = value.map do |v|
          serialize v
        end.join(",")

        "[#{serialized_array}]"
      else
        JSON.generate(value, quirks_mode: true)
      end
    end
  end
end
