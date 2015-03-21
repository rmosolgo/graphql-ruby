require "active_support/core_ext/object/blank"
require "active_support/core_ext/string/inflections"
require "json"
require "parslet"
require "singleton"

module GraphQL
  autoload(:Call,                     "graphql/call")
  autoload(:Connection,               "graphql/connection")
  autoload(:Field,                    "graphql/field")
  autoload(:FieldDefiner,             "graphql/field_definer")
  autoload(:FieldMapping,             "graphql/field_mapping")
  autoload(:Node,                     "graphql/node")
  autoload(:Query,                    "graphql/query")
  autoload(:RootCall,                 "graphql/root_call")
  autoload(:RootCallArgument,         "graphql/root_call_argument")
  autoload(:RootCallArgumentDefiner,  "graphql/root_call_argument_definer")
  autoload(:VERSION,                  "graphql/version")

  # These fields wrap Ruby data types and some GraphQL internal values.
  module Fields
    autoload(:BooleanField,     "graphql/fields/boolean_field")
    autoload(:ConnectionField,  "graphql/fields/connection_field")
    autoload(:CursorField,      "graphql/fields/cursor_field")
    autoload(:NumberField,      "graphql/fields/number_field")
    autoload(:ObjectField,      "graphql/fields/object_field")
    autoload(:StringField,      "graphql/fields/string_field")
    autoload(:TypeField,        "graphql/fields/type_field")
  end

  # These objects are used for introspections (eg, responding to `schema()` calls).
  module Introspection
    autoload(:CallNode,             "graphql/introspection/call_node")
    autoload(:Connection,           "graphql/introspection/connection")
    autoload(:ConnectionField,      "graphql/introspection/connection_field")
    autoload(:FieldNode,            "graphql/introspection/field_node")
    autoload(:RootCallArgumentNode, "graphql/introspection/root_call_argument_node")
    autoload(:RootCallNode,         "graphql/introspection/root_call_node")
    autoload(:SchemaCall,           "graphql/introspection/schema_call")
    autoload(:SchemaNode,           "graphql/introspection/schema_node")
    autoload(:TypeCall,             "graphql/introspection/type_call")
    autoload(:TypeNode,             "graphql/introspection/type_node")
  end

  # These objects are singletons used to parse queries
  module Parser
    autoload(:Parser,     "graphql/parser/parser")
    autoload(:Transform,  "graphql/parser/transform")
  end

  # These objects are used to track the schema of the graph
  module Schema
    autoload(:Schema,           "graphql/schema/schema")
    autoload(:SchemaValidation, "graphql/schema/schema_validation")
  end

  # These objects are skinny wrappers for going from the AST to actual {Node} and {Field} instances.
  module Syntax
    autoload(:Call,       "graphql/syntax/call")
    autoload(:Field,      "graphql/syntax/field")
    autoload(:Query,      "graphql/syntax/query")
    autoload(:Node,       "graphql/syntax/node")
    autoload(:Variable,   "graphql/syntax/variable")
  end

  # @abstract
  # Base class for all errors, so you can rescue from all graphql errors at once.
  class Error < RuntimeError; end
  # This node doesn't have a field with that name.
  class FieldNotDefinedError < Error
    def initialize(node_class, field_name)
      class_name = node_class.name
      defined_field_names = node_class.all_fields.keys
      super("#{class_name}##{field_name} was requested, but it isn't defined. Defined fields are: #{defined_field_names}")
    end
  end
  # This field type isn't in the schema.
  class FieldTypeMissingError < Error
    def initialize(field_type_name)
      super("field.#{field_type_name} was requested, but it isn't defined. Defined field types are: #{SCHEMA.field_names}")
    end
  end
  # The class that this node is supposed to expose isn't defined
  class ExposesClassMissingError < Error
    def initialize(node_class)
      super("#{node_class.name} exposes #{node_class.exposes_class_name}, but that class wasn't found.")
    end
  end
  # There's no Node defined for that kind of object.
  class NodeNotDefinedError < Error
    def initialize(node_name)
      super("#{node_name} was requested but was not found. Defined nodes are: #{SCHEMA.type_names}")
    end
  end
  # This node doesn't have a connection with that name.
  class  ConnectionNotDefinedError < Error
    def initialize(node_name)
      super("#{node_name} was requested but was not found. Defined connections are: #{SCHEMA.connection_names}")
    end
  end
  # The root call of this query isn't in the schema.
  class RootCallNotDefinedError < Error
    def initialize(name)
      super("Call '#{name}' was requested but was not found. Defined calls are: #{SCHEMA.call_names}")
    end
  end
  # The query couldn't be parsed.
  class SyntaxError < Error
    def initialize(line, col, string)
      lines = string.split("\n")
      super("Syntax Error at (#{line}, #{col}), check usage: #{string}")
    end
  end
  # This root call takes different arguments.
  class RootCallArgumentError < Error
    def initialize(declaration, actual)
      super("Wrong type for #{declaration.name}: expected a #{declaration.type} but got #{actual}")
    end
  end

  # Singleton {Parser::Parser} instance
  PARSER = Parser::Parser.new
  # This singleton contains all defined nodes and fields.
  SCHEMA = Schema::Schema.instance
  # Singleton {Parser::Transform} instance
  TRANSFORM = Parser::Transform.new
  # preload these so they're in SCHEMA
  ["fields", "introspection"].each do |preload_dir|
    Dir["#{File.dirname(__FILE__)}/graphql/#{preload_dir}/*.rb"].each { |f| require f }
  end
  Node.field.__type__(:__type__)
end