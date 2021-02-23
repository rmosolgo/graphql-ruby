%%{
  machine graphql_lexer;

  IDENTIFIER =    [_A-Za-z][_0-9A-Za-z]*;
  NEWLINE =       [\c\r\n];
  BLANK   =       [, \t]+;
  COMMENT =       '#' [^\n\r]*;
  INT =           '-'? ('0'|[1-9][0-9]*);
  FLOAT_DECIMAL = '.'[0-9]+;
  FLOAT_EXP =     ('e' | 'E')?('+' | '-')?[0-9]+;
  FLOAT =         INT FLOAT_DECIMAL? FLOAT_EXP?;
  ON =            'on';
  FRAGMENT =      'fragment';
  TRUE =          'true';
  FALSE =         'false';
  NULL =          'null';
  QUERY =         'query';
  MUTATION =      'mutation';
  SUBSCRIPTION =  'subscription';
  SCHEMA =        'schema';
  SCALAR =        'scalar';
  TYPE =          'type';
  EXTEND =        'extend';
  IMPLEMENTS =    'implements';
  INTERFACE =     'interface';
  UNION =         'union';
  ENUM =          'enum';
  INPUT =         'input';
  DIRECTIVE =     'directive';
  LCURLY =        '{';
  RCURLY =        '}';
  LPAREN =        '(';
  RPAREN =        ')';
  LBRACKET =      '[';
  RBRACKET =      ']';
  COLON =         ':';
  QUOTE =         '"';
  BACKSLASH = '\\';
  # Could limit to hex here, but “bad unicode escape” on 0XXF is probably a
  # more helpful error than “unknown char”
  UNICODE_ESCAPE = '\\u' [0-9A-Za-z]{4};
  # https://graphql.github.io/graphql-spec/June2018/#sec-String-Value
  STRING_ESCAPE = '\\' [\\/bfnrt];
  BLOCK_QUOTE =   '"""';
  ESCAPED_BLOCK_QUOTE = '\\"""';
  BLOCK_STRING_CHAR = (ESCAPED_BLOCK_QUOTE | ^QUOTE | QUOTE{1,2} ^QUOTE);
  ESCAPED_QUOTE = '\\"';
  STRING_CHAR =   ((ESCAPED_QUOTE | ^QUOTE) - BACKSLASH) | UNICODE_ESCAPE | STRING_ESCAPE;
  VAR_SIGN =      '$';
  DIR_SIGN =      '@';
  ELLIPSIS =      '...';
  EQUALS =        '=';
  BANG =          '!';
  PIPE =          '|';
  AMP =           '&';

  QUOTED_STRING = QUOTE STRING_CHAR* QUOTE;
  BLOCK_STRING = BLOCK_QUOTE BLOCK_STRING_CHAR* QUOTE{0,2} BLOCK_QUOTE;
  # catch-all for anything else. must be at the bottom for precedence.
  UNKNOWN_CHAR =         /./;

  # Used with ragel -V for graphviz visualization
  str := |*
      QUOTED_STRING => { emit_string(ts, te, meta, block: false) };
  *|;

  main := |*
    INT           => { emit(:INT, ts, te, meta) };
    FLOAT         => { emit(:FLOAT, ts, te, meta) };
    ON            => { emit(:ON, ts, te, meta, "on") };
    FRAGMENT      => { emit(:FRAGMENT, ts, te, meta, "fragment") };
    TRUE          => { emit(:TRUE, ts, te, meta, "true") };
    FALSE         => { emit(:FALSE, ts, te, meta, "false") };
    NULL          => { emit(:NULL, ts, te, meta, "null") };
    QUERY         => { emit(:QUERY, ts, te, meta, "query") };
    MUTATION      => { emit(:MUTATION, ts, te, meta, "mutation") };
    SUBSCRIPTION  => { emit(:SUBSCRIPTION, ts, te, meta, "subscription") };
    SCHEMA        => { emit(:SCHEMA, ts, te, meta) };
    SCALAR        => { emit(:SCALAR, ts, te, meta) };
    TYPE          => { emit(:TYPE, ts, te, meta) };
    EXTEND        => { emit(:EXTEND, ts, te, meta) };
    IMPLEMENTS    => { emit(:IMPLEMENTS, ts, te, meta) };
    INTERFACE     => { emit(:INTERFACE, ts, te, meta) };
    UNION         => { emit(:UNION, ts, te, meta) };
    ENUM          => { emit(:ENUM, ts, te, meta) };
    INPUT         => { emit(:INPUT, ts, te, meta) };
    DIRECTIVE     => { emit(:DIRECTIVE, ts, te, meta) };
    RCURLY        => { emit(:RCURLY, ts, te, meta, "}") };
    LCURLY        => { emit(:LCURLY, ts, te, meta, "{") };
    RPAREN        => { emit(:RPAREN, ts, te, meta, ")") };
    LPAREN        => { emit(:LPAREN, ts, te, meta, "(")};
    RBRACKET      => { emit(:RBRACKET, ts, te, meta, "]") };
    LBRACKET      => { emit(:LBRACKET, ts, te, meta, "[") };
    COLON         => { emit(:COLON, ts, te, meta, ":") };
    QUOTED_STRING => { emit_string(ts, te, meta, block: false) };
    BLOCK_STRING  => { emit_string(ts, te, meta, block: true) };
    VAR_SIGN      => { emit(:VAR_SIGN, ts, te, meta, "$") };
    DIR_SIGN      => { emit(:DIR_SIGN, ts, te, meta, "@") };
    ELLIPSIS      => { emit(:ELLIPSIS, ts, te, meta, "...") };
    EQUALS        => { emit(:EQUALS, ts, te, meta, "=") };
    BANG          => { emit(:BANG, ts, te, meta, "!") };
    PIPE          => { emit(:PIPE, ts, te, meta, "|") };
    AMP           => { emit(:AMP, ts, te, meta, "&") };
    IDENTIFIER    => { emit(:IDENTIFIER, ts, te, meta) };
    COMMENT       => { record_comment(ts, te, meta) };

    NEWLINE => {
      meta[:line] += 1
      meta[:col] = 1
    };

    BLANK   => { meta[:col] += te - ts };

    UNKNOWN_CHAR => { emit(:UNKNOWN_CHAR, ts, te, meta) };

  *|;
}%%

# frozen_string_literal: true

module GraphQL
  module Language
    module Lexer
      if !String.method_defined?(:match?)
        using GraphQL::StringMatchBackport
      end

      def self.tokenize(query_string)
        run_lexer(query_string)
      end

      # Replace any escaped unicode or whitespace with the _actual_ characters
      # To avoid allocating more strings, this modifies the string passed into it
      def self.replace_escaped_characters_in_place(raw_string)
        raw_string.gsub!(ESCAPES, ESCAPES_REPLACE)
        raw_string.gsub!(UTF_8, &UTF_8_REPLACE)
        nil
      end

      private

      %% write data;

      def self.run_lexer(query_string)
        data = query_string.unpack(PACK_DIRECTIVE)
        eof = data.length

        # Since `Lexer` is a module, store all lexer state
        # in this local variable:
        meta = {
          line: 1,
          col: 1,
          data: data,
          tokens: [],
          previous_token: nil,
        }

        p ||= 0
        pe ||= data.length

        %% write init;

        %% write exec;

        meta[:tokens]
      end

      def self.record_comment(ts, te, meta)
        token = GraphQL::Language::Token.new(
          :COMMENT,
          meta[:data][ts, te - ts].pack(PACK_DIRECTIVE).force_encoding(UTF_8_ENCODING),
          meta[:line],
          meta[:col],
          meta[:previous_token],
        )

        meta[:previous_token] = token

        meta[:col] += te - ts
      end

      def self.emit(token_name, ts, te, meta, token_value = nil)
        token_value ||= meta[:data][ts, te - ts].pack(PACK_DIRECTIVE).force_encoding(UTF_8_ENCODING)
        meta[:tokens] << token = GraphQL::Language::Token.new(
          token_name,
          token_value,
          meta[:line],
          meta[:col],
          meta[:previous_token],
        )
        meta[:previous_token] = token
        # Bump the column counter for the next token
        meta[:col] += te - ts
      end

      ESCAPES = /\\["\\\/bfnrt]/
      ESCAPES_REPLACE = {
        '\\"' => '"',
        "\\\\" => "\\",
        "\\/" => '/',
        "\\b" => "\b",
        "\\f" => "\f",
        "\\n" => "\n",
        "\\r" => "\r",
        "\\t" => "\t",
      }

      UTF_8 = /\\u[\dAa-f]{4}/i
      UTF_8_REPLACE = ->(m) { [m[-4..-1].to_i(16)].pack('U'.freeze) }

      VALID_STRING = /\A(?:[^\\]|#{ESCAPES}|#{UTF_8})*\z/o

      PACK_DIRECTIVE = "c*"
      UTF_8_ENCODING = "UTF-8"

      def self.emit_string(ts, te, meta, block:)
        quotes_length = block ? 3 : 1
        value = meta[:data][ts + quotes_length, te - ts - 2 * quotes_length].pack(PACK_DIRECTIVE).force_encoding(UTF_8_ENCODING) || ''
        line_incr = 0
        if block && !value.empty?
          line_incr = value.count("\n")
          value = GraphQL::Language::BlockString.trim_whitespace(value)
        end
        # TODO: replace with `String#match?` when we support only Ruby 2.4+
        # (It's faster: https://bugs.ruby-lang.org/issues/8110)
        if !value.valid_encoding? || !value.match?(VALID_STRING)
          meta[:tokens] << token = GraphQL::Language::Token.new(
            :BAD_UNICODE_ESCAPE,
            value,
            meta[:line],
            meta[:col],
            meta[:previous_token],
          )
        else
          replace_escaped_characters_in_place(value)

          if !value.valid_encoding?
            meta[:tokens] << token = GraphQL::Language::Token.new(
              :BAD_UNICODE_ESCAPE,
              value,
              meta[:line],
              meta[:col],
              meta[:previous_token],
            )
          else
            meta[:tokens] << token = GraphQL::Language::Token.new(
              :STRING,
              value,
              meta[:line],
              meta[:col],
              meta[:previous_token],
            )
          end
        end

        meta[:previous_token] = token
        meta[:col] += te - ts
        meta[:line] += line_incr
      end
    end
  end
end
