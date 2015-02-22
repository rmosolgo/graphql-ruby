require "active_support/core_ext/object/blank"
require "active_support/core_ext/string/inflections"
require "json"
require "parslet"
require "singleton"

module GraphQL
  autoload(:Call,             "graphql/call")
  autoload(:Connection,       "graphql/connection")
  autoload(:Field,            "graphql/field")
  autoload(:FieldDefiner,     "graphql/field_definer")
  autoload(:Node,             "graphql/node")
  autoload(:Parser,           "graphql/parser")
  autoload(:Query,            "graphql/query")
  autoload(:RootCall,         "graphql/root_call")
  autoload(:RootCallArgument,         "graphql/root_call_argument")
  autoload(:RootCallArgumentDefiner,         "graphql/root_call_argument_definer")
  autoload(:Schema,           "graphql/schema")
  autoload(:Transform,        "graphql/transform")
  autoload(:VERSION,          "graphql/version")

  module Introspection
    autoload(:CallNode,             "graphql/introspection/call_node")
    autoload(:Connection,           "graphql/introspection/connection")
    autoload(:FieldNode,            "graphql/introspection/field_node")
    autoload(:RootCallArgumentNode, "graphql/introspection/root_call_argument_node")
    autoload(:RootCallNode,         "graphql/introspection/root_call_node")
    autoload(:SchemaCall,           "graphql/introspection/schema_call")
    autoload(:SchemaNode,           "graphql/introspection/schema_node")
    autoload(:TypeCall,             "graphql/introspection/type_call")
    autoload(:TypeNode,             "graphql/introspection/type_node")
  end


  module Syntax
    autoload(:Call,       "graphql/syntax/call")
    autoload(:Field,      "graphql/syntax/field")
    autoload(:Query,      "graphql/syntax/query")
    autoload(:Node,       "graphql/syntax/node")
    autoload(:Variable,   "graphql/syntax/variable")
  end

  module Types
    autoload(:BooleanField,     "graphql/types/boolean_field")
    autoload(:ConnectionField,  "graphql/types/connection_field")
    autoload(:CursorField,      "graphql/types/cursor_field")
    autoload(:NumberField,      "graphql/types/number_field")
    autoload(:ObjectField,      "graphql/types/object_field")
    autoload(:StringField,      "graphql/types/string_field")
    autoload(:TypeField,        "graphql/types/type_field")
  end

  class Error < RuntimeError; end
  class FieldNotDefinedError < Error
    def initialize(class_name, field_name)
      super("#{class_name}##{field_name} was requested, but it isn't defined. Defined fields are: #{SCHEMA.field_names}")
    end
  end
  class NodeNotDefinedError < Error
    def initialize(node_name)
      super("#{node_name} was requested but was not found. Defined nodes are: #{SCHEMA.type_names}")
    end
  end
  class  ConnectionNotDefinedError < Error
    def initialize(node_name)
      super("#{node_name} was requested but was not found. Defined connections are: #{SCHEMA.connection_names}")
    end
  end
  class RootCallNotDefinedError < Error
    def initialize(name)
      super("Call '#{name}' was requested but was not found. Defined calls are: #{SCHEMA.call_names}")
    end
  end
  class SyntaxError < Error
    def initialize(line, col, string)
      lines = string.split("\n")
      super("Syntax Error at (#{line}, #{col}), check usage: #{string}")
    end
  end

  class RootCallArgumentError < Error
    def initialize(declaration, actual)
      super("Wrong type for #{declaration.name}: expected a #{declaration.type} but got #{actual}")
    end
  end

  PARSER = Parser.new
  SCHEMA = Schema.instance
  TRANSFORM = Transform.new
  # preload these so they're in SCHEMA
  ["types", "introspection"].each do |preload_dir|
    Dir["#{File.dirname(__FILE__)}/graphql/#{preload_dir}/*.rb"].each { |f| require f }
  end
  Node.field.__type__(:__type__)
end