# frozen_string_literal: true
require "delegate"
require "json"
require "set"
require "singleton"
require "forwardable"

module GraphQL
  # forwards-compat for argument handling
  module Ruby2Keywords
    if RUBY_VERSION < "2.7"
      def ruby2_keywords(*)
      end
    end
  end

  class Error < StandardError
  end

  # This error is raised when GraphQL-Ruby encounters a situation
  # that it *thought* would never happen. Please report this bug!
  class InvariantError < Error
    def initialize(message)
      message += "

This is probably a bug in GraphQL-Ruby, please report this error on GitHub: https://github.com/rmosolgo/graphql-ruby/issues/new?template=bug_report.md"
      super(message)
    end
  end

  class RequiredImplementationMissingError < Error
  end

  class << self
    def default_parser
      @default_parser ||= GraphQL::Language::Parser
    end

    attr_writer :default_parser
  end

  # Turn a query string or schema definition into an AST
  # @param graphql_string [String] a GraphQL query string or schema definition
  # @return [GraphQL::Language::Nodes::Document]
  def self.parse(graphql_string, trace: GraphQL::Tracing::NullTrace)
    default_parser.parse(graphql_string, trace: trace)
  end

  # Read the contents of `filename` and parse them as GraphQL
  # @param filename [String] Path to a `.graphql` file containing IDL or query
  # @return [GraphQL::Language::Nodes::Document]
  def self.parse_file(filename)
    content = File.read(filename)
    default_parser.parse(content, filename: filename)
  end

  # @return [Array<Array>]
  def self.scan(graphql_string)
    default_parser.scan(graphql_string)
  end

  def self.parse_with_racc(string, filename: nil, trace: GraphQL::Tracing::NullTrace)
    GraphQL::Language::Parser.parse(string, filename: filename, trace: trace)
  end

  def self.scan_with_ruby(graphql_string)
    GraphQL::Language::Lexer.tokenize(graphql_string)
  end

  NOT_CONFIGURED = Object.new
  private_constant :NOT_CONFIGURED
  module EmptyObjects
    EMPTY_HASH = {}.freeze
    EMPTY_ARRAY = [].freeze
  end
end

# Order matters for these:

require "graphql/execution_error"
require "graphql/runtime_type_error"
require "graphql/unresolved_type_error"
require "graphql/invalid_null_error"
require "graphql/analysis_error"
require "graphql/coercion_error"
require "graphql/invalid_name_error"
require "graphql/integer_decoding_error"
require "graphql/integer_encoding_error"
require "graphql/string_encoding_error"
require "graphql/date_encoding_error"
require "graphql/type_kinds"
require "graphql/name_validator"
require "graphql/language"

require_relative "./graphql/railtie" if defined? Rails::Railtie

require "graphql/analysis"
require "graphql/tracing"
require "graphql/dig"
require "graphql/execution"
require "graphql/pagination"
require "graphql/schema"
require "graphql/query"
require "graphql/types"
require "graphql/dataloader"
require "graphql/filter"
require "graphql/static_validation"
require "graphql/execution"
require "graphql/schema/built_in_types"
require "graphql/schema/loader"
require "graphql/schema/printer"
require "graphql/introspection"
require "graphql/relay"

require "graphql/version"
require "graphql/subscriptions"
require "graphql/parse_error"
require "graphql/backtrace"

require "graphql/unauthorized_error"
require "graphql/unauthorized_field_error"
require "graphql/load_application_object_failed_error"
require "graphql/deprecation"
