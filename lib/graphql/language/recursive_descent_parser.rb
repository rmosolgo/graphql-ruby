# frozen_string_literal: true

require "strscan"
require "graphql/language/nodes"

module GraphQL
  module Language
    class RecursiveDescentParser
      include GraphQL::Language::Nodes

      def self.parse(graphql_str)
        self.new(graphql_str).parse
      end

      def initialize(graphql_str)
        @lexer = Lexer.new(graphql_str)
        @graphql_str = graphql_str
      end

      def parse
        @document ||= document
      end

      private

      attr_reader :token_name

      def advance_token
        @token_name = @lexer.advance
      end

      def document
        advance_token
        defns = []
        while !lexer.eos?
          defns << definition
        end
        Document.new(line: 0, col: 0, definitions: defns)
      end

      def definition
        case token_name
        when :FRAGMENT, :QUERY, :MUTATION, :SUBSCRIPTION, :LCURLY
          executable_definition
        # when :EXTEND
        #   type_system_extension
        # else
        #   desc = if at?(:STRING); string_value; end

        #   type_system_definition desc
        end
      end


      class Lexer
        def initialize(graphql_str)
          @string = graphql_str
          @scanner = StringScanner.new(graphql_str)
          @pos = nil
        end

        def eos?
          @scanner.eos?
        end

        attr_reader :pos

        def advance
          return false if @scanner.eos?
          @pos = @scanner.pos
          next_byte = @string.get_byte(@pos)
          next_byte_is_for = FIRST_BYTES[next_byte]
          case next_byte_is_for
          when ByteFor::PUNCTUATION
            @scanner.pos += 1
            PUNCTUATION_NAME_FOR_BYTE[next_byte]
          when ByteFor::NAME
            if len = @scanner.skip(KEYWORD_REGEXP)
              case len
              when 2
                :ON
              when 12
                :SUBSCRIPTION
              else
                pos = @pos

                # Use bytes 2 and 3 as a unique identifier for this keyword
                bytes = (@string.getbyte(pos + 2) << 8) | @string.getbyte(pos + 1)
                KEYWORD_BY_TWO_BYTES[_hash(bytes)]
              end
            else
              @scanner.skip(IDENTIFIER_REGEXP)
              :IDENTIFIER
            end
          when ByteFor::IDENTIFIER
            @scanner.skip(IDENTIFIER_REGEXP)
            :IDENTIFIER
          when ByteFor::NUMBER
            @scanner.skip(NUMERIC_REGEXP)
            # Check for a matched decimal:
            @scanner[1] ? :FLOAT : :INT
          when ByteFor::ELLIPSIS
            if @string.getbyte(@pos + 1) != 46 || @string.getbyte(@pos + 2) != 46
              raise "TODO raise a nice error for a malformed ellipsis"
            end
            @scanner.pos += 3
            :ELLIPSIS
          when ByteFor::STRING
            if @scanner.skip(QUOTED_STRING_REGEXP) || @scanner.skip(BLOCK_STRING_REGEXP)
            else
              raise "TODO Raise a nice error for a badly-formatted string"
            end
          else
            @scanner.pos += 1
            :UNKNOWN_CHAR
          end
        end

        def token_value
          @string.byteslice(@scanner.pos - @scanner.matched_size, @scanner.matched_size)
        end

        def string_value
          str = token_value
          is_block = str.start_with?('"""')
          str.gsub!(/\A"*|"*\z/, '')

          if is_block
            str = Language::BlockString.trim_whitespace(str)
          end

          if !str.valid_encoding? || !str.match?(Language::Lexer::VALID_STRING)
            raise "TODO Bad Unicode escape"
          else
            GraphQL::Language::Lexer.replace_escaped_characters_in_place(str)

            if !value.valid_encoding?
              raise "TODO Bad Unicode escape"
            else
              str
            end
          end
        end

        IDENTIFIER_REGEXP = /[_A-Za-z][_0-9A-Za-z]*/
        INT_REGEXP =        /[-]?(?:[0]|[1-9][0-9]*)/
        FLOAT_DECIMAL_REGEXP = /[.][0-9]+/
        FLOAT_EXP_REGEXP =     /[eE][+-]?[0-9]+/
        NUMERIC_REGEXP =  /#{INT_REGEXP}(#{FLOAT_DECIMAL_REGEXP}#{FLOAT_EXP_REGEXP}|#{FLOAT_DECIMAL_REGEXP}|#{FLOAT_EXP_REGEXP})?/

        KEYWORDS = [
          "on",
          "fragment",
          "true",
          "false",
          "null",
          "query",
          "mutation",
          "subscription",
          "schema",
          "scalar",
          "type",
          "extend",
          "implements",
          "interface",
          "union",
          "enum",
          "input",
          "directive",
          "repeatable"
        ].freeze

        KEYWORD_REGEXP = /#{Regexp.union(KEYWORDS.sort)}\b/
        KEYWORD_BY_TWO_BYTES = [
          :INTERFACE,
          :MUTATION,
          :EXTEND,
          :FALSE,
          :ENUM,
          :TRUE,
          :NULL,
          nil,
          nil,
          nil,
          nil,
          nil,
          nil,
          nil,
          :QUERY,
          nil,
          nil,
          :REPEATABLE,
          :IMPLEMENTS,
          :INPUT,
          :TYPE,
          :SCHEMA,
          nil,
          nil,
          nil,
          :DIRECTIVE,
          :UNION,
          nil,
          nil,
          :SCALAR,
          nil,
          :FRAGMENT
        ]

        # This produces a unique integer for bytes 2 and 3 of each keyword string
        # See https://tenderlovemaking.com/2023/09/02/fast-tokenizers-with-stringscanner.html
        def _hash key
          (key * 18592990) >> 27 & 0x1f
        end

        module Punctuation
          LCURLY =        '{'
          RCURLY =        '}'
          LPAREN =        '('
          RPAREN =        ')'
          LBRACKET =      '['
          RBRACKET =      ']'
          COLON =         ':'
          VAR_SIGN =      '$'
          DIR_SIGN =      '@'
          EQUALS =        '='
          BANG =          '!'
          PIPE =          '|'
          AMP =           '&'
        end

        # A sparse array mapping the bytes for each punctuation
        # to a symbol name for that punctuation
        PUNCTUATION_NAME_FOR_BYTE = Punctuation.constants.each_with_object([]) { |name, arr|
          punct = Punctuation.const_get(name)
          arr[punct.ord] = name
        }

        # Use this array to check, for a given byte that will start a token,
        # what kind of token might it start?
        FIRST_BYTES = Array.new(255) { 0 }

        module ByteFor
          NUMBER = 0 # int or float
          NAME = 1 # identifier or keyword
          STRING = 2
          ELLIPSIS = 3
          IDENTIFIER = 4 # identifier, *not* a keyword
          PUNCTUATION = 5
        end

        (0..9).each { |i| FIRST_BYTES[i.to_s.ord] = ByteFor::NUMBER }
        # Some of these may be overwritten below, if keywords start with the same character
        ("A".."Z").each { |char| FIRST_BYTES[char.ord] = ByteFor::IDENTIFIER }
        ("a".."z").each { |char| FIRST_BYTES[char.ord] = ByteFor::IDENTIFIER }
        FIRST_BYTES['_'.ord] = ByteFor::IDENTIFIER
        FIRST_BYTES['.'.ord] = ByteFor::ELLIPSIS
        FIRST_BYTES['"'.ord] = ByteFor::STRING
        KEYWORDS.each { |kw| FIRST_BYTES[kw.getbyte(0)] = ByteFor::NAME }
        Punctuation.constants.each do |punct_name|
          punct = Punctuation.const_get(punct_name)
          FIRST_BYTES[punct.ord] = ByteFor::PUNCTUATION
        end

      end
    end
  end
end
