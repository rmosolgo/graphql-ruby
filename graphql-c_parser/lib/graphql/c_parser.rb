# frozen_string_literal: true

require "graphql"
require "graphql/c_parser/version"
require "graphql/graphql_c_parser_ext"

module GraphQL
  module CParser
    def self.parse(query_str, filename, trace)
      parser = Parser.new(query_str, filename, trace)
      parser.result
    end

    def self.prepare_parse_error(message, parser)
      if message.start_with?("memory exhausted")
        return GraphQL::ParseError.new("This query is too large to execute.", nil, nil, parser.query_string, filename: parser.filename)
      end
      token = parser.tokens[parser.next_token_index - 1]
      line = token[1]
      col = token[2]
      if line && col
        location_str = " at [#{line}, #{col}]"
        if !message.include?(location_str)
          message += location_str
        end
      end

      message.sub!(/, unexpected ([a-zA-Z ]+),/, ", unexpected \\1 (#{token[3].inspect}),")

      GraphQL::ParseError.new(message, line, col, parser.query_string, filename: parser.filename)
    end

    class Parser
      def initialize(query_string, filename, trace)
        @query_string = query_string
        @filename = filename
        @tokens = nil
        @next_token_index = 0
        @result = nil
        @trace = trace
      end

      def result
        if @result.nil?
          @tokens = @trace.lex(query_string: @query_string) do
            GraphQL::CParser::Lexer.tokenize(@query_string)
          end
          @trace.parse(query_string: @query_string) do
            c_parse
            @result
          end
        end
        @result
      end

      attr_reader :tokens, :next_token_index, :query_string, :filename
    end
  end

  def self.scan_with_c(graphql_string)
    GraphQL::CParser::Lexer.tokenize(graphql_string)
  end

  def self.parse_with_c(string, filename: nil, trace: GraphQL::Tracing::NullTrace)
    if string.nil?
      raise GraphQL::ParseError.new("No query string was present", nil, nil, string)
    end
    document = GraphQL::CParser.parse(string, filename, trace)
    if document.definitions.size == 0
      raise GraphQL::ParseError.new("Unexpected end of document", 1, 1, string)
    end
    document
  end

  # Call CParser implementations by default:
  def self.scan(str)
    scan_with_c(str)
  end

  def self.parse(*args, **kwargs)
    parse_with_c(*args, **kwargs)
  end
end
