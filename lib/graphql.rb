require "json"
require "parslet"
require "singleton"

module GraphQL
  # Turn a query string into an AST
  # @param string [String] a GraphQL query string
  # @param as [Symbol] If you want to use this to parse some _piece_ of a document, pass the rule name (from {GraphQL::Parser::Parser})
  # @return [GraphQL::Nodes::Document]
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

require 'graph_ql/definition_helpers'
require 'graph_ql/object_type'

require 'graph_ql/enum_type'
require 'graph_ql/input_object_type'
require 'graph_ql/interface_type'
require 'graph_ql/list_type'
require 'graph_ql/non_null_type'
require 'graph_ql/union_type'

require 'graph_ql/argument'
require 'graph_ql/field'
require 'graph_ql/type_kinds'
require 'graph_ql/introspection/typename_field'

require 'graph_ql/scalar_type'
require 'graph_ql/boolean_type'
require 'graph_ql/float_type'
require 'graph_ql/id_type'
require 'graph_ql/int_type'
require 'graph_ql/string_type'

require 'graph_ql/introspection/input_value_type'
require 'graph_ql/introspection/enum_value_type'
require 'graph_ql/introspection/type_kind_enum'

require 'graph_ql/introspection/fields_field'
require 'graph_ql/introspection/of_type_field'
require 'graph_ql/introspection/input_fields_field'
require 'graph_ql/introspection/possible_types_field'
require 'graph_ql/introspection/enum_values_field'
require 'graph_ql/introspection/interfaces_field'

require 'graph_ql/introspection/type_type'
require 'graph_ql/introspection/arguments_field'
require 'graph_ql/introspection/field_type'

require 'graph_ql/introspection/directive_type'
require 'graph_ql/introspection/schema_type'
require 'graph_ql/introspection/schema_field'
require 'graph_ql/introspection/type_by_name_field'
require 'graph_ql/introspection/introspection_query'

require 'graph_ql/nodes'
require 'graph_ql/parser'
require 'graph_ql/transform'
require 'graph_ql/visitor'
require 'graph_ql/directive'
require 'graph_ql/schema'

# Order does not matter for these:

require 'graph_ql/query'
require 'graph_ql/repl'
require 'graph_ql/static_validation'
require 'graph_ql/version'
