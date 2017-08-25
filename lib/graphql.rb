# frozen_string_literal: true
require "delegate"
require "json"
require "set"
require "singleton"

module GraphQL
  # Ruby stdlib was pretty busted until this fix:
  # https://github.com/ruby/ruby/commit/46c0e79bb5b96c45c166ef62f8e585f528862abb#diff-43adf0e587a50dbaf51764a262008d40
  module Delegate
    def def_delegators(accessor, *method_names)
      method_names.each do |method_name|
        class_eval <<-RUBY
        def #{method_name}(*args)
          if block_given?
            #{accessor}.#{method_name}(*args, &Proc.new)
          else
            #{accessor}.#{method_name}(*args)
          end
        end
        RUBY
      end
    end
  end

  class Error < StandardError
  end

  # Turn a query string or schema definition into an AST
  # @param graphql_string [String] a GraphQL query string or schema definition
  # @return [GraphQL::Language::Nodes::Document]
  def self.parse(graphql_string)
    parse_with_racc(graphql_string)
  end

  # Read the contents of `filename` and parse them as GraphQL
  # @param filename [String] Path to a `.graphql` file containing IDL or query
  # @return [GraphQL::Language::Nodes::Document]
  def self.parse_file(filename)
    content = File.read(filename)
    parse_with_racc(content, filename: filename)
  end

  def self.parse_with_racc(string, filename: nil)
    GraphQL::Language::Parser.parse(string, filename: filename)
  end

  # @return [Array<GraphQL::Language::Token>]
  def self.scan(graphql_string)
    scan_with_ragel(graphql_string)
  end

  def self.scan_with_ragel(graphql_string)
    GraphQL::Language::Lexer.tokenize(graphql_string)
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
require "graphql/boolean_type"
require "graphql/float_type"
require "graphql/id_type"
require "graphql/int_type"
require "graphql/string_type"
require "graphql/directive"

require "graphql/introspection"
require "graphql/language"
require "graphql/analysis"
require "graphql/execution"
require "graphql/relay"
require "graphql/schema"
require "graphql/schema/loader"
require "graphql/schema/printer"

require "graphql/analysis_error"
require "graphql/runtime_type_error"
require "graphql/invalid_null_error"
require "graphql/unresolved_type_error"
require "graphql/string_encoding_error"
require "graphql/query"
require "graphql/internal_representation"
require "graphql/static_validation"
require "graphql/version"
require "graphql/compatibility"
require "graphql/function"
require "graphql/filter"
require "graphql/parse_error"
require "graphql/tracing"
