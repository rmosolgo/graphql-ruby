# frozen_string_literal: true
require "graphql/language/block_string"
require "graphql/language/printer"
require "graphql/language/sanitized_printer"
require "graphql/language/document_from_schema_definition"
require "graphql/language/generation"
require "graphql/language/lexer"
require "graphql/language/nodes"
require "graphql/language/cache"
require "graphql/language/parser"
require "graphql/language/static_visitor"
require "graphql/language/token"
require "graphql/language/visitor"
require "graphql/language/definition_slice"
require "strscan"

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

    # Returns a new string if any single-quoted newlines were escaped.
    # Otherwise, returns `query_str` unchanged.
    # @return [String]
    def self.escape_single_quoted_newlines(query_str)
      scanner = StringScanner.new(query_str)
      inside_single_quoted_string = false
      new_query_str = nil
      while !scanner.eos?
        if (match = scanner.scan(/(?:\\"|[^"\n\r]|""")+/m)) && new_query_str
          new_query_str << match
        elsif scanner.scan('"')
          new_query_str && (new_query_str << '"')
          inside_single_quoted_string = !inside_single_quoted_string
        elsif scanner.scan("\n")
          if inside_single_quoted_string
            new_query_str ||= query_str[0, scanner.pos - 1]
            new_query_str << '\\n'
          else
            new_query_str && (new_query_str << "\n")
          end
        elsif scanner.scan("\r")
          if inside_single_quoted_string
            new_query_str ||= query_str[0, scanner.pos - 1]
            new_query_str << '\\r'
          else
            new_query_str && (new_query_str << "\r")
          end
        elsif scanner.eos?
          break
        else
          raise ArgumentError, "Unmatchable string scanner segment: #{scanner.rest.inspect}"
        end
      end
      new_query_str || query_str
    end
  end
end
