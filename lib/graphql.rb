require "active_support/core_ext/object/blank"
require "active_support/core_ext/string/inflections"
require "json"
require "parslet"

module GraphQL
  autoload(:Connection,       "graphql/connection")
  autoload(:Field,            "graphql/field")
  autoload(:Node,             "graphql/node")
  autoload(:Parser,           "graphql/parser")
  autoload(:Query,            "graphql/query")
  autoload(:RootCall,         "graphql/root_call")
  autoload(:Schema,           "graphql/schema")
  autoload(:Transform,        "graphql/transform")
  autoload(:VERSION,          "graphql/version")

  module Introspection
    autoload(:CallNode,           "graphql/introspection/call_node")
    autoload(:FieldNode,          "graphql/introspection/field_node")
    autoload(:FieldsConnection,   "graphql/introspection/fields_connection")
    autoload(:SchemaCall,         "graphql/introspection/schema_call")
    autoload(:SchemaConnection,   "graphql/introspection/schema_connection")
    autoload(:SchemaNode,         "graphql/introspection/schema_node")
    autoload(:TypeCall,           "graphql/introspection/type_call")
    autoload(:TypeNode,           "graphql/introspection/type_node")
  end


  module Syntax
    autoload(:Call,       "graphql/syntax/call")
    autoload(:Field,      "graphql/syntax/field")
    autoload(:Query,      "graphql/syntax/query")
    autoload(:Node,       "graphql/syntax/node")
    autoload(:Variable,   "graphql/syntax/variable")
  end

  module Types
    autoload(:ConnectionField,  "graphql/types/connection_field")
    autoload(:CursorField,      "graphql/types/cursor_field")
    autoload(:NumberField,      "graphql/types/number_field")
    autoload(:ObjectField,      "graphql/types/object_field")
    autoload(:StringField,      "graphql/types/string_field")
  end

  TYPE_ALIASES = {}
  PARSER = Parser.new
  SCHEMA = Schema.new
  TRANSFORM = Transform.new
  # auto-load these so they're in SCHEMA
  Introspection::SchemaCall
  Introspection::SchemaConnection
  Introspection::SchemaNode
  Introspection::TypeCall
  Introspection::TypeNode

  class FieldNotDefinedError < RuntimeError
    def initialize(class_name, field_name)
      super("#{class_name}##{field_name} was requested, but it isn't defined.")
    end
  end
  class NodeNotDefinedError < RuntimeError
    def initialize(node_name)
      super("#{node_name} was requested but was not found. Defined nodes are: #{SCHEMA.node_names}")
    end
  end
  class RootCallNotDefinedError < RuntimeError
    def initialize(name)
      super("Call '#{name}' was requested but was not found. Defined calls are: #{SCHEMA.call_names}")
    end
  end
  class SyntaxError < RuntimeError
    def initialize(line, col, string)
      lines = string.split("\n")
      super("Syntax Error at (#{line}, #{col}), check usage: #{string}")
    end
  end
end