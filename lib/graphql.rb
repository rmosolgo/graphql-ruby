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
  def self.parse(graphql_string, tracer: GraphQL::Tracing::NullTracer)
    parse_with_racc(graphql_string, tracer: tracer)
  end

  # Read the contents of `filename` and parse them as GraphQL
  # @param filename [String] Path to a `.graphql` file containing IDL or query
  # @return [GraphQL::Language::Nodes::Document]
  def self.parse_file(filename)
    content = File.read(filename)
    parse_with_racc(content, filename: filename)
  end

  def self.parse_with_racc(string, filename: nil, tracer: GraphQL::Tracing::NullTracer)
    GraphQL::Language::Parser.parse(string, filename: filename, tracer: tracer)
  end

  # @return [Array<GraphQL::Language::Token>]
  def self.scan(graphql_string)
    scan_with_ragel(graphql_string)
  end

  def self.scan_with_ragel(graphql_string)
    GraphQL::Language::Lexer.tokenize(graphql_string)
  end

  # Support Ruby 2.2 by implementing `-"str"`. If we drop 2.2 support, we can remove this backport.
  module StringDedupBackport
    refine String do
      def -@
        if frozen?
          self
        else
          self.dup.freeze
        end
      end
    end
  end

  module StringMatchBackport
    refine String do
      def match?(pattern)
        self =~ pattern
      end
    end
  end
end

# Order matters for these:

require "graphql/execution_error"
require "graphql/define"
require "graphql/base_type"
require "graphql/object_type"

require "graphql/enum_type"
require "graphql/input_object_type"
require "graphql/interface_type"
require "graphql/list_type"
require "graphql/non_null_type"
require "graphql/union_type"

require "graphql/argument"
require "graphql/field"
require "graphql/type_kinds"

require "graphql/backwards_compatibility"
require "graphql/scalar_type"

require "graphql/name_validator"

require "graphql/language"

require_relative "./graphql/railtie" if defined? Rails::Railtie

require "graphql/analysis"
require "graphql/tracing"
require "graphql/dig"
require "graphql/execution"
require "graphql/runtime_type_error"
require "graphql/unresolved_type_error"
require "graphql/invalid_null_error"
require "graphql/pagination"
require "graphql/schema"
require "graphql/query"
require "graphql/directive"
require "graphql/execution"
require "graphql/types"
require "graphql/relay"
require "graphql/boolean_type"
require "graphql/float_type"
require "graphql/id_type"
require "graphql/int_type"
require "graphql/string_type"
require "graphql/schema/built_in_types"
require "graphql/schema/loader"
require "graphql/schema/printer"
require "graphql/filter"
require "graphql/internal_representation"
require "graphql/static_validation"
require "graphql/dataloader"
require "graphql/introspection"

require "graphql/analysis_error"
require "graphql/coercion_error"
require "graphql/invalid_name_error"
require "graphql/integer_decoding_error"
require "graphql/integer_encoding_error"
require "graphql/string_encoding_error"
require "graphql/version"
require "graphql/compatibility"
require "graphql/function"
require "graphql/subscriptions"
require "graphql/parse_error"
require "graphql/backtrace"

require "graphql/deprecated_dsl"
require "graphql/authorization"
require "graphql/unauthorized_error"
require "graphql/unauthorized_field_error"
require "graphql/load_application_object_failed_error"
require "graphql/deprecation"

module GraphQL
  # Ruby has `deprecate_constant`,
  # but I don't see a way to give a nice error message in that case,
  # so I'm doing this instead.
  DEPRECATED_INT_TYPE = INT_TYPE
  DEPRECATED_FLOAT_TYPE = FLOAT_TYPE
  DEPRECATED_STRING_TYPE = STRING_TYPE
  DEPRECATED_BOOLEAN_TYPE = BOOLEAN_TYPE
  DEPRECATED_ID_TYPE = ID_TYPE

  remove_const :INT_TYPE
  remove_const :FLOAT_TYPE
  remove_const :STRING_TYPE
  remove_const :BOOLEAN_TYPE
  remove_const :ID_TYPE

  def self.const_missing(const_name)
    deprecated_const_name = :"DEPRECATED_#{const_name}"
    if const_defined?(deprecated_const_name)
      deprecated_type = const_get(deprecated_const_name)
      deprecated_caller = caller(1, 1).first
      # Don't warn about internal uses, like `types.Int`
      if !deprecated_caller.include?("lib/graphql")
        warn "GraphQL::#{const_name} is deprecated and will be removed in GraphQL-Ruby 2.0, use GraphQL::Types::#{deprecated_type.graphql_name} instead. (from #{deprecated_caller})"
      end
      deprecated_type
    else
      super
    end
  end
end
