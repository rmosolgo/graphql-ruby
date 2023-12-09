# frozen_string_literal: true

require "strscan"
require "graphql/language/nodes"

module GraphQL
  module Language
    class RecursiveDescentParser
      include GraphQL::Language::Nodes
      include EmptyObjects

      def self.parse(graphql_str, filename: nil, trace: Tracing::NullTrace)
        self.new(graphql_str, filename: filename, trace: trace).parse
      end

      def initialize(graphql_str, filename: nil, trace: Tracing::NullTrace)
        if graphql_str.nil?
          raise GraphQL::ParseError.new("No query string was present", nil, nil, nil)
        end
        @lexer = Lexer.new(graphql_str)
        @graphql_str = graphql_str
        @filename = filename
        @trace = trace
      end

      def parse
        @document ||= begin
          @trace.parse(query_string: @graphql_str) do
            document
          end
        end
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
          f_name = if !at?(:ON)
            parse_name
          end
          expect_token :ON
          f_type = parse_type_name
          directives = parse_directives

          Nodes::FragmentDefinition.new(
            pos: loc,
            name: f_name,
            type: f_type,
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

          op_name = at?(:IDENTIFIER) ? parse_name : ""

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
                advance_token
                value
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
        when :EXTEND
          expect_token(:EXTEND)
          case token_name
          when :SCALAR
            loc = pos
            expect_token :SCALAR
            name = parse_name
            directives = parse_directives
            ScalarTypeExtension.new(pos: loc, name: name, directives: directives)
          when :TYPE
            loc = pos
            expect_token :TYPE
            name = parse_name
            implements_interfaces = parse_implements
            directives = parse_directives
            field_defns = at?(:LCURLY) ? parse_field_definitions : EMPTY_ARRAY

            ObjectTypeExtension.new(pos: loc, name: name, interfaces: implements_interfaces, directives: directives, fields: field_defns)
          when :INTERFACE
            loc = pos
            expect_token :INTERFACE
            name = parse_name
            directives = parse_directives
            interfaces = parse_implements
            fields_definition = at?(:LCURLY) ? parse_field_definitions : EMPTY_ARRAY
            InterfaceTypeExtension.new(pos: loc, name: name, directives: directives, fields: fields_definition, interfaces: interfaces)
          when :UNION
            loc = pos
            expect_token :UNION
            name = parse_name
            directives = parse_directives
            union_member_types = parse_union_members
            UnionTypeExtension.new(pos: loc, name: name, directives: directives, types: union_member_types)
          when :ENUM
            loc = pos
            expect_token :ENUM
            name = parse_name
            directives = parse_directives
            enum_values_definition = parse_enum_value_definitions
            Nodes::EnumTypeExtension.new(pos: loc, name: name, directives: directives, values: enum_values_definition)
          when :INPUT
            loc = pos
            expect_token :INPUT
            name = parse_name
            directives = parse_directives
            input_fields_definition = parse_input_object_field_definitions
            InputObjectTypeExtension.new(pos: loc, name: name, directives: directives, fields: input_fields_definition)
          else
            expect_one_of([:SCALAR, :TYPE, :ENUM, :INPUT, :UNION, :INTERFACE])
          end
        else
          desc = at?(:STRING) ? string_value : nil

          case token_name
          when :SCHEMA
            loc = pos
            expect_token :SCHEMA
            directives = parse_directives
            query = mutation = subscription = nil
            expect_token :LCURLY
            while !at?(:RCURLY)
              if at?(:QUERY)
                advance_token
                expect_token(:COLON)
                query = parse_name
              elsif at?(:MUTATION)
                advance_token
                expect_token(:COLON)
                mutation = parse_name
              elsif at?(:SUBSCRIPTION)
                advance_token
                expect_token(:COLON)
                subscription = parse_name
              else
                expect_one_of([:QUERY, :MUTATION, :SUBSCRIPTION])
              end
            end
            expect_token :RCURLY
            SchemaDefinition.new(pos: loc, query: query, mutation: mutation, subscription: subscription, directives: directives)
          when :DIRECTIVE
            loc = pos
            expect_token :DIRECTIVE
            expect_token :DIR_SIGN
            name = parse_name
            arguments_definition = parse_argument_definitions
            repeatable = if at?(:REPEATABLE)
              advance_token
              true
            else
              fasle
            end
            expect_token :ON
            directive_locations = [DirectiveLocation.new(pos: pos, name: parse_name)]
            while at?(:PIPE)
              advance_token
              directive_locations << DirectiveLocation.new(pos: pos, name: parse_name)
            end
            DirectiveDefinition.new(pos: loc, description: desc, name: name, arguments: arguments_definition, locations: directive_locations, repeatable: repeatable)
          when :TYPE
            loc = pos
            expect_token :TYPE
            name = parse_name
            implements_interfaces = parse_implements
            directives = parse_directives
            field_defns = parse_field_definitions

            ObjectTypeDefinition.new(pos: loc, description: desc, name: name, interfaces: implements_interfaces, directives: directives, fields: field_defns)
          when :INTERFACE
            loc = pos
            expect_token :INTERFACE
            name = parse_name
            directives = parse_directives
            interfaces = parse_implements
            fields_definition = parse_field_definitions
            InterfaceTypeDefinition.new(pos: loc, description: desc, name: name, directives: directives, fields: fields_definition, interfaces: interfaces)
          when :UNION
            loc = pos
            expect_token :UNION
            name = parse_name
            directives = parse_directives
            union_member_types = parse_union_members
            UnionTypeDefinition.new(pos: loc, description: desc, name: name, directives: directives, types: union_member_types)
          when :SCALAR
            loc = pos
            expect_token :SCALAR
            name = parse_name
            directives = parse_directives
            ScalarTypeDefinition.new(pos: loc, description: desc, name: name, directives: directives)
          when :ENUM
            loc = pos
            expect_token :ENUM
            name = parse_name
            directives = parse_directives
            enum_values_definition = parse_enum_value_definitions
            Nodes::EnumTypeDefinition.new(pos: loc, description: desc, name: name, directives: directives, values: enum_values_definition)
          when :INPUT
            loc = pos
            expect_token :INPUT
            name = parse_name
            directives = parse_directives
            input_fields_definition = parse_input_object_field_definitions
            InputObjectTypeDefinition.new(pos: loc, description: desc, name: name, directives: directives, fields: input_fields_definition)
          else
            expect_one_of([:SCALAR, :TYPE, :ENUM, :INPUT, :UNION, :INTERFACE])
          end
        end
      end

      def parse_input_object_field_definitions
        if at?(:LCURLY)
          expect_token :LCURLY
          list = []
          while !at?(:RCURLY)
            list << parse_input_value_definition
          end
          expect_token :RCURLY
          list
        else
          EMPTY_ARRAY
        end
      end

      def parse_enum_value_definitions
        if at?(:LCURLY)
          expect_token :LCURLY
          list = []
          while !at?(:RCURLY)
            v_loc = pos
            description = if at?(:STRING); string_value; end
            enum_value = expect_token_value(:IDENTIFIER)
            v_directives = parse_directives
            list << EnumValueDefinition.new(pos: v_loc, description: description, name: enum_value, directives: v_directives)
          end
          expect_token :RCURLY
          list
        else
          EMPTY_ARRAY
        end
      end

      def parse_union_members
        if at?(:EQUALS)
          expect_token :EQUALS
          list = [parse_type_name]
          while at?(:PIPE)
            advance_token
            list << parse_type_name
          end
          list
        else
          EMPTY_ARRAY
        end
      end

      def parse_implements
        if at?(:IMPLEMENTS)
          advance_token
          list = []
          while true
            advance_token if at?(:AMP)
            break unless at?(:IDENTIFIER)
            list << parse_type_name
          end
          list
        else
          EMPTY_ARRAY
        end
      end

      def parse_field_definitions
        expect_token :LCURLY
        list = []
        while !at?(:RCURLY)
          loc = pos
          description = if at?(:STRING); string_value; end
          name = parse_name
          arguments_definition = parse_argument_definitions
          expect_token :COLON
          type = self.type
          directives = parse_directives

          list << FieldDefinition.new(pos: loc, description: description, name: name, arguments: arguments_definition, type: type, directives: directives)
        end
        expect_token :RCURLY
        list
      end

      def parse_argument_definitions
        if at?(:LPAREN)
          advance_token
          list = []
          while !at?(:RPAREN)
            list << parse_input_value_definition
          end
          expect_token :RPAREN
          list
        else
          EMPTY_ARRAY
        end
      end

      def parse_input_value_definition
        loc = pos
        description = if at?(:STRING); string_value; end
        name = parse_name
        expect_token :COLON
        type = self.type
        default_value = if at?(:EQUALS)
          advance_token
          value
        else
          nil
        end
        directives = parse_directives
        InputValueDefinition.new(pos: loc, description: description, name: name, type: type, default_value: default_value, directives: directives)
      end

      def type
        type = case token_name
        when :IDENTIFIER
          parse_type_name
        when :LBRACKET
          list_type
        end

        if at?(:BANG)
          type = Nodes::NonNullType.new(pos: pos, of_type: type)
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
        while @token_name != :RCURLY
          selections << if at?(:ELLIPSIS)
            advance_token
            case token_name
            when :ON, :DIR_SIGN, :LCURLY
              loc = pos
              if_type = if at?(:ON)
                advance_token
                parse_type_name
              else
                nil
              end

              directives = parse_directives

              Nodes::InlineFragment.new(pos: loc, type: if_type, directives: directives, selections: selection_set)
            else
              loc = pos
              name = parse_name_without_on
              directives = parse_directives

              # Can this ever happen?
              # expect_token(:IDENTIFIER) if at?(:ON)

              FragmentSpread.new(pos: loc, name: name, directives: directives)
            end
          else
            loc = pos
            name = parse_name

            field_alias = nil

            if at?(:COLON)
              advance_token
              field_alias = name
              name = parse_name
            end

            arguments = at?(:LPAREN) ? parse_arguments : nil
            directives = at?(:DIR_SIGN) ? parse_directives : nil
            selection_set = at?(:LCURLY) ? self.selection_set : nil

            Nodes::Field.new(pos: loc, alias: field_alias, name: name, arguments: arguments, directives: directives, selections: selection_set)
          end
        end
        expect_token(:RCURLY)
        selections
      end

      def parse_name
        case token_name
        when :IDENTIFIER
          expect_token_value(:IDENTIFIER)
        when :SCHEMA
          advance_token
          "schema"
        when :SCALAR
          advance_token
          "scalar"
        when :IMPLEMENTS
          advance_token
          "implements"
        when :INTERFACE
          advance_token
          "interface"
        when :UNION
          advance_token
          "union"
        when :ENUM
          advance_token
          "enum"
        when :INPUT
          advance_token
          "input"
        when :DIRECTIVE
          advance_token
          "directive"
        when :TYPE
          advance_token
          "type"
        when :QUERY
          advance_token
          "query"
        when :MUTATION
          advance_token
          "mutation"
        when :SUBSCRIPTION
          advance_token
          "subscription"
        when :TRUE
          advance_token
          "true"
        when :FALSE
          advance_token
          "false"
        when :FRAGMENT
          advance_token
          "fragment"
        when :REPEATABLE
          advance_token
          "repeatable"
        when :NULL
          advance_token
          "null"
        else
          expect_token(:IDENTIFIER)
        end
      end

      def parse_name_without_on
        if at?(:ON)
          expect_token(:IDENTIFIER)
        else
          parse_name
        end
      end

      # Any identifier, but not true, false, or null
      def parse_enum_name
        if at?(:TRUE) || at?(:FALSE) || at?(:NULL)
          expect_token(:IDENTIFIER)
        else
          parse_name
        end
      end

      def parse_type_name
        TypeName.new(pos: pos, name: parse_name)
      end

      def parse_directives
        if at?(:DIR_SIGN)
          dirs = []
          while at?(:DIR_SIGN)
            loc = pos
            advance_token
            name = parse_name
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
            name = parse_name
            expect_token(:COLON)
            args << Nodes::Argument.new(pos: loc, name: name, value: value)
          end
          expect_token(:RPAREN)
          args
        else
          EMPTY_ARRAY
        end
      end

      def string_value
        token_value = @lexer.string_value
        expect_token :STRING
        token_value
      end

      def value
        case token_name
        when :INT
          expect_token_value(:INT).to_i
        when :FLOAT
          expect_token_value(:FLOAT).to_f
        when :STRING
          string_value
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
            n = parse_name
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
          raise_parse_error("Expected #{expected_token_name}, actual: #{token_name} (#{@lexer.token_value.inspect})")
        end
        advance_token
      end

      def expect_one_of(token_names)
        raise_parse_error("Expected one of #{token_names.join(", ")}, actual: #{token_name} (#{@lexer.token_value.inspect})")
      end

      def raise_parse_error(message)
        message += " at [#{@lexer.line_number}, #{@lexer.column_number}]"
        raise GraphQL::ParseError.new(
          message,
          @lexer.line_number,
          @lexer.column_number,
          @graphql_str,
          filename: @filename,
        )

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
              raise_parse_error("Expected `...`, actual: #{@string[@pos..@pos + 2].inspect}")
            end
            @scanner.pos += 3
            :ELLIPSIS
          when ByteFor::STRING
            if @scanner.skip(BLOCK_STRING_REGEXP) || @scanner.skip(QUOTED_STRING_REGEXP)
              :STRING
            else
              raise_parse_error("Expected string or block string, but it was malformed")
            end
          else
            @scanner.pos += 1
            :UNKNOWN_CHAR
          end
        end

        def token_value
          @string.byteslice(@scanner.pos - @scanner.matched_size, @scanner.matched_size)
        rescue StandardError => err
          raise GraphQL::Error, "(token_value failed: #{err.class}: #{err.message})"
        end

        def string_value
          str = token_value
          is_block = str.start_with?('"""')
          str.gsub!(/\A"*|"*\z/, '')

          if is_block
            str = Language::BlockString.trim_whitespace(str)
          end

          if !str.valid_encoding? || !str.match?(Language::Lexer::VALID_STRING)
            raise_parse_error("Bad unicode escape in #{str.inspect}")
          else
            GraphQL::Language::Lexer.replace_escaped_characters_in_place(str)

            if !str.valid_encoding?
              raise_parse_error("Bad unicode escape in #{str.inspect}")
            else
              str
            end
          end
        end

        def line_number
          @scanner.string[0, @scanner.pos].count("\n") + 1
        end

        def column_number
          @scanner.string[0, @scanner.pos].split("\n").last.length - token_value.length + 1
        end

        # IGNORE_REGEXP = /[, \c\r\n\t]+/
        IGNORE_REGEXP =       %r{
          (?:
            [, \c\r\n\t]+ |
            \#.*$
          )*
        }x
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
