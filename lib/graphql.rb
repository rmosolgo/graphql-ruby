# frozen_string_literal: true
require "delegate"
require "json"
require "set"
require "singleton"
require "forwardable"
require_relative "./graphql/railtie" if defined? Rails::Railtie

module GraphQL
  class RecursionGuard
    attr_accessor :trace, :guard_name, :object

    def initialize(object, guard_name)
      self.guard_name = guard_name
      self.object = object
      self.trace = caller
      
      if guard_hash.include?(guard_name)
        raise <<~STR
          Recursive invocation detected in #{object.class.name}##{guard_name}

          ############################################################################################
          Original Stack Trace:
          ############################################################################################
          #{guard_hash[guard_name].trace.join("\n")}

          ############################################################################################
          Second Stack Trace:
          ############################################################################################
          #{caller.join("\n")}"
        STR
      end

      guard_hash[guard_name] = self
    end

    def guard_hash
      hash = object.instance_variable_get(:@__recursion_guard)
      hash ||= object.instance_variable_set(:@__recursion_guard, {})
    end

    def dispose
      guard_hash.delete(guard_name)
      object.remove_instance_variable(:@__recursion_guard) if guard_hash.empty?
    end

    def self.guard(object, guard_name)
      guard = new(object, guard_name)
      begin
        return yield
      ensure
        guard.dispose
      end
    end
  end

  class Error < StandardError
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

require "graphql/directive"
require "graphql/name_validator"

require "graphql/language"
require "graphql/analysis"
require "graphql/tracing"
require "graphql/execution"
require "graphql/relay"
require "graphql/schema"
require "graphql/boolean_type"
require "graphql/float_type"
require "graphql/id_type"
require "graphql/int_type"
require "graphql/string_type"
require "graphql/schema/built_in_types"
require "graphql/schema/loader"
require "graphql/schema/printer"
require "graphql/introspection"

require "graphql/analysis_error"
require "graphql/coercion_error"
require "graphql/runtime_type_error"
require "graphql/invalid_null_error"
require "graphql/invalid_name_error"
require "graphql/unresolved_type_error"
require "graphql/string_encoding_error"
require "graphql/query"
require "graphql/internal_representation"
require "graphql/static_validation"
require "graphql/version"
require "graphql/compatibility"
require "graphql/function"
require "graphql/filter"
require "graphql/subscriptions"
require "graphql/parse_error"
require "graphql/backtrace"

require "graphql/deprecated_dsl"
