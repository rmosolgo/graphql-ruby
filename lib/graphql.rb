require "json"
require "parslet"
require "singleton"

module GraphQL
  # Turn a query string into an AST
  # @param string [String] a GraphQL query string
  # @param as [Symbol] If you want to use this to parse some _piece_ of a document, pass the rule name (from {GraphQL::Parser})
  # @return [GraphQL::Language::Nodes::Document]
  def self.parse(string, as: nil)
    parser = as ? GraphQL::PARSER.send(as) : GraphQL::PARSER
    tree = parser.parse(string)
    GraphQL::TRANSFORM.apply(tree)
  rescue Parslet::ParseFailed => error
    line, col = error.cause.source.line_and_column
    raise [line, col, string].join(", ")
  end

  # Types & Fields that support GraphQL introspection queries
  module Introspection; end
end

# Order matters for these:

require 'graphql/definition_helpers'
require 'graphql/object_type'

require 'graphql/enum_type'
require 'graphql/input_object_type'
require 'graphql/interface_type'
require 'graphql/list_type'
require 'graphql/non_null_type'
require 'graphql/union_type'

require 'graphql/argument'
require 'graphql/field'
require 'graphql/type_kinds'
require 'graphql/introspection/typename_field'

require 'graphql/scalar_type'
require 'graphql/boolean_type'
require 'graphql/float_type'
require 'graphql/id_type'
require 'graphql/int_type'
require 'graphql/string_type'

require 'graphql/introspection/input_value_type'
require 'graphql/introspection/enum_value_type'
require 'graphql/introspection/type_kind_enum'

require 'graphql/introspection/fields_field'
require 'graphql/introspection/of_type_field'
require 'graphql/introspection/input_fields_field'
require 'graphql/introspection/possible_types_field'
require 'graphql/introspection/enum_values_field'
require 'graphql/introspection/interfaces_field'

require 'graphql/introspection/type_type'
require 'graphql/introspection/arguments_field'
require 'graphql/introspection/field_type'

require 'graphql/introspection/directive_type'
require 'graphql/introspection/schema_type'
require 'graphql/introspection/schema_field'
require 'graphql/introspection/type_by_name_field'
require 'graphql/introspection/introspection_query'

require 'graphql/language'
require 'graphql/directive'
require 'graphql/schema'

# Order does not matter for these:

require 'graphql/query'
require 'graphql/repl'
require 'graphql/static_validation'
require 'graphql/version'
