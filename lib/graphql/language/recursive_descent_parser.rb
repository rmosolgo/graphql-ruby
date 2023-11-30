# frozen_string_literal: true

require "strscan"
require "graphql/language/nodes"

module GraphQL
  module Language
    class RecursiveDescentParser
      include GraphQL::Language::Nodes
      include EmptyObjects

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

      def pos
        @lexer.pos
      end

      def document
        advance_token
        defns = []
        while !@lexer.eos?
          defns << definition
        end
        Document.new(pos: 0, definitions: defns)
      end

      def definition
        case token_name
        when :FRAGMENT
          loc = pos
          expect_token :FRAGMENT
          expect_token(:IDENTIFIER) if at?(:ON)
          f_name = self.name
          expect_token :ON
          t_loc = pos
          t_name = name
          directives = parse_directives

          Nodes::FragmentDefinition.new(
            pos: loc,
            name: f_name,
            type: TypeName.new(pos: t_loc, name: t_name),
            directives: directives,
            selections: selection_set
          )
        when :QUERY, :MUTATION, :SUBSCRIPTION, :LCURLY
          loc = pos
          op_type = case token_name
          when :LCURLY
            "query"
          else
            self.operation_type
          end

          op_name = at?(:IDENTIFIER) ? name : ""

          variable_definitions = if at?(:LPAREN)
            expect_token(:LPAREN)
            defs = []
            while !at?(:RPAREN)
              loc = pos
              expect_token(:VAR_SIGN)
              var_name = expect_token_value(:IDENTIFIER)
              expect_token(:COLON)
              var_type = self.type
              default_value = if at?(:EQUALS)
                self.default_value
              end

              defs << Nodes::VariableDefinition.new(pos: loc, name: var_name, type: var_type, default_value: default_value)
            end
            expect_token(:RPAREN)
            defs
          else
            EmptyObjects::EMPTY_ARRAY
          end

          directives = parse_directives

          OperationDefinition.new(
            pos: loc,
            operation_type: op_type,
            name: op_name,
            variables: variable_definitions,
            directives: directives,
            selections: selection_set,
          )
        # when :EXTEND
        #   type_system_extension
        # else
        #   desc = if at?(:STRING); string_value; end

        #   type_system_definition desc
        else
          expect_token(:ROOT_DEFINITON)
        end


      end

      def type
        type = case token_name
        when :IDENTIFIER
          TypeName.new(pos: pos, name: name)
        when :LBRACKET
          list_type
        end

        if at?(:BANG)
          Nodes::NonNullType.new(pos: pos, of_type: type)
          expect_token(:BANG)
        end
        type
      end

      def list_type
        loc = pos
        expect_token(:LBRACKET)
        type = Nodes::ListType.new(pos: loc, of_type: self.type)
        expect_token(:RBRACKET)
        type
      end

      def operation_type
        val = if at?(:QUERY)
          "query"
        elsif at?(:MUTATION)
          "mutation"
        elsif at?(:SUBSCRIPTION)
          "subscription"
        else
          expect_token(:QUERY)
        end
        advance_token
        val
      end

      def selection_set
        expect_token(:LCURLY)
        selections = []
        while !at?(:RCURLY)
          selections << if at?(:ELLIPSIS)
            expect_token(:ELLIPSIS)
            case token_name
            when :ON, :DIR_SIGN, :LCURLY
              loc = pos
              if_type = if at?(:ON)
                advance_token
                TypeName.new(pos: pos, name: name)
              else
                nil
              end

              directives = parse_directives

              Nodes::InlineFragment.new(pos: loc, type: if_type, directives: directives, selections: selection_set)
            when :IDENTIFIER
              loc = pos
              name = self.name
              directives = parse_directives

              # Can this ever happen?
              # expect_token(:IDENTIFIER) if at?(:ON)

              FragmentSpread.new(pos: loc, name: name, directives: directives)
            else
              expect_token(:FRAGMENT_SPREAD)
            end
          else
            loc = pos
            name = self.name

            aliaz = nil

            if at?(:COLON)
              expect_token(:COLON)
              aliaz = name
              name = self.name
            end

            arguments = parse_arguments
            directives = parse_directives
            selection_set = if at?(:LCURLY); self.selection_set; end

            Nodes::Field.new(pos: loc, alias: aliaz, name: name, arguments: arguments, directives: directives, selections: selection_set)
          end
        end
        expect_token(:RCURLY)
        selections
      end

      def name
        case token_name
        when :IDENTIFIER
          expect_token_value(:IDENTIFIER)
        when :TYPE
          advance_token
          "type"
        when :QUERY
          advance_token
          "query"
        when :INPUT
          advance_token
          "input"
        else
          expect_token(:IDENTIFIER)
        end
      end

      def parse_directives
        if at?(:DIR_SIGN)
          dirs = []
          while at?(:DIR_SIGN)
            loc = pos
            expect_token(:DIR_SIGN)
            name = self.name
            arguments = parse_arguments

            dirs << Nodes::Directive.new(pos: loc, name: name, arguments: arguments)
          end
          dirs
        else
          EMPTY_ARRAY
        end
      end

      def parse_arguments
        if at?(:LPAREN)
          advance_token
          args = []
          while !at?(:RPAREN)
            loc = pos
            name = self.name
            expect_token(:COLON)
            args << Nodes::Argument.new(pos: loc, name: name, value: value)
          end
          expect_token(:RPAREN)
          args
        else
          EMPTY_ARRAY
        end
      end

      def value
        case token_name
        when :INT
          expect_token_value(:INT).to_i
        when :FLOAT
          expect_token_value(:FLOAT).to_f
        when :STRING
          token_value = @lexer.string_value
          expect_token :STRING
          token_value
        when :TRUE
          advance_token
          true
        when :FALSE
          advance_token
          false
        when :NULL
          advance_token
          NullValue.new(pos: pos, name: "null")
        when :IDENTIFIER
          Nodes::Enum.new(pos: pos, name: expect_token_value(:IDENTIFIER))
        when :LBRACKET
          advance_token
          list = []
          while !at?(:RBRACKET)
            list << value
          end
          expect_token(:RBRACKET)
          list
        when :LCURLY
          start = pos
          advance_token
          args = []
          while !at?(:RCURLY)
            loc = pos
            n = name
            expect_token(:COLON)
            args << Argument.new(pos: loc, name: n, value: value)
          end
          expect_token(:RCURLY)
          InputObject.new(pos: start, arguments: args)
        when :VAR_SIGN
          loc = pos
          advance_token
          VariableIdentifier.new(pos: loc, name: expect_token_value(:IDENTIFIER))
        else
          expect_token(:VALUE)
        end
      end

      def at?(expected_token_name)
        @token_name == expected_token_name
      end

      def expect_token(expected_token_name)
        unless @token_name == expected_token_name
          raise "TODO nice error for Expected token #{expected_token_name}, actual: #{token_name.inspect} #{@lexer.token_value} line: #{@lexer.line} / pos: #{@lexer.pos}"
        end
        advance_token
      end

      # Only use when we care about the expected token's value
      def expect_token_value(tok)
        token_value = @lexer.token_value
        expect_token(tok)
        token_value
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
          @scanner.skip(IGNORE_REGEXP)
          return false if @scanner.eos?
          @pos = @scanner.pos
          next_byte = @string.getbyte(@pos)
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
              :STRING
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
        rescue StandardError => err
          "(token_value failed: #{err.class}: #{err.message})"
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

            if !str.valid_encoding?
              raise "TODO Bad Unicode escape"
            else
              str
            end
          end
        end

        def line
          @scanner.string[0, @scanner.pos].count("\n") + 1
        end

        IGNORE_REGEXP = /[, \c\r\n\t]+/
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

        QUOTE =         '"'
        UNICODE_DIGIT = /[0-9A-Za-z]/
        FOUR_DIGIT_UNICODE = /#{UNICODE_DIGIT}{4}/
        N_DIGIT_UNICODE = %r{#{Punctuation::LCURLY}#{UNICODE_DIGIT}{4,}#{Punctuation::RCURLY}}x
        UNICODE_ESCAPE = %r{\\u(?:#{FOUR_DIGIT_UNICODE}|#{N_DIGIT_UNICODE})}
        # # https://graphql.github.io/graphql-spec/June2018/#sec-String-Value
        STRING_ESCAPE = %r{[\\][\\/bfnrt]}
        BLOCK_QUOTE =   '"""'
        ESCAPED_QUOTE = /\\"/;
        STRING_CHAR = /#{ESCAPED_QUOTE}|[^"\\]|#{UNICODE_ESCAPE}|#{STRING_ESCAPE}/
        QUOTED_STRING_REGEXP = %r{#{QUOTE} (?:#{STRING_CHAR})* #{QUOTE}}x
        BLOCK_STRING_REGEXP = %r{
          #{BLOCK_QUOTE}
          (?: [^"\\]               |  # Any characters that aren't a quote or slash
             (?<!") ["]{1,2} (?!") |  # Any quotes that don't have quotes next to them
             \\"{0,3}(?!")         |  # A slash followed by <= 3 quotes that aren't followed by a quote
             \\                    |  # A slash
             "{1,2}(?!")              # 1 or 2 " followed by something that isn't a quote
          )*
          (?:"")?
          #{BLOCK_QUOTE}
        }xm

        # Use this array to check, for a given byte that will start a token,
        # what kind of token might it start?
        FIRST_BYTES = Array.new(255)

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
