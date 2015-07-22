require "json"
require "parslet"
require "singleton"

module GraphQL
  def self.parse(string, as: nil)
    parser = as ? GraphQL::PARSER.send(as) : GraphQL::PARSER
    tree = parser.parse(string)
    GraphQL::TRANSFORM.apply(tree)
  rescue Parslet::ParseFailed => error
    line, col = error.cause.source.line_and_column
    raise [line, col, string].join(", ")
  end

  module Definable
    def attr_definable(*names)
      attr_accessor(*names)
      names.each do |name|
        ivar_name = "@#{name}".to_sym
        define_method(name) do |new_value=nil|
          new_value && self.instance_variable_set(ivar_name, new_value)
          instance_variable_get(ivar_name)
        end
      end
    end
  end

  module Forwardable
    def delegate(*methods, to:)
      methods.each do |method_name|
        define_method(method_name) do |*args|
          self.public_send(to).public_send(method_name, *args)
        end
      end
    end
  end

  class StringNamedHash
    attr_reader :to_h
    def initialize(input_hash)
      @to_h = input_hash
        .reduce({}) { |memo, (key, value)| memo[key.to_s] = value; memo }
      # Set the name of the value based on its key
      @to_h.each {|k, v| v.respond_to?("name=") && v.name = k }
    end
  end

  module Introspection; end
end

# Order matters for these:

require 'graph_ql/types/non_null_with_bang'
require 'graph_ql/types/object_type'
require 'graph_ql/types/list_type'
require 'graph_ql/types/scalar_type'
require 'graph_ql/types/non_null_type'
require 'graph_ql/types/input_value'
require 'graph_ql/types/input_object_type'

require 'graph_ql/types/type_definer'
require 'graph_ql/types/field_definer'
require 'graph_ql/types/argument_definer'

require 'graph_ql/enum'
require 'graph_ql/field'
require 'graph_ql/union'
require 'graph_ql/type_kinds'
require 'graph_ql/introspection/typename_field'

require 'graph_ql/types/int_type'
require 'graph_ql/types/string_type'
require 'graph_ql/types/float_type'
require 'graph_ql/types/boolean_type'

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
require 'graph_ql/introspection/field_type'

require 'graph_ql/introspection/arguments_field'
require 'graph_ql/introspection/directive_type'
require 'graph_ql/introspection/schema_type'

require 'graph_ql/parser'
require 'graph_ql/directive'
require 'graph_ql/schema'

# Order does not matter for these:

require 'graph_ql/interface'
require 'graph_ql/query'
require 'graph_ql/repl'
require 'graph_ql/static_validation'
require 'graph_ql/version'
