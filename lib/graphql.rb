require "active_support/core_ext/object/blank"
require "active_support/core_ext/string/inflections"
require "json"
require "parslet"

module GraphQL
  autoload(:Call,                     "graphql/call")
  autoload(:Connection,               "graphql/connection")
  autoload(:FieldDefiner,             "graphql/field_definer")
  autoload(:Field,                    "graphql/field")
  autoload(:Node,                     "graphql/node")
  autoload(:Query,                    "graphql/query")
  autoload(:RootCall,                 "graphql/root_call")
  autoload(:RootCallArgument,         "graphql/root_call_argument")
  autoload(:RootCallArgumentDefiner,  "graphql/root_call_argument_definer")
  autoload(:TestCallChain,            "graphql/testing/test_call_chain")
  autoload(:TestNode,                 "graphql/testing/test_node")
  autoload(:VERSION,                  "graphql/version")

  # These objects are used for introspections (eg, responding to `schema()` calls).
  module Introspection
    autoload(:CallType,             "graphql/introspection/call_type")
    autoload(:Connection,           "graphql/introspection/connection")
    autoload(:FieldType,            "graphql/introspection/field_type")
    autoload(:RootCallArgumentNode, "graphql/introspection/root_call_argument_node")
    autoload(:RootCallType,         "graphql/introspection/root_call_type")
    autoload(:SchemaCall,           "graphql/introspection/schema_call")
    autoload(:SchemaType,           "graphql/introspection/schema_type")
    autoload(:TypeCall,             "graphql/introspection/type_call")
    autoload(:TypeType,             "graphql/introspection/type_type")
  end

  # These objects are singletons used to parse queries
  module Parser
    autoload(:Parser,     "graphql/parser/parser")
    autoload(:Transform,  "graphql/parser/transform")
  end

  # These objects are used to track the schema of the graph
  module Schema
    autoload(:ALL,              "graphql/schema/all")
    autoload(:Schema,           "graphql/schema/schema")
    autoload(:SchemaValidation, "graphql/schema/schema_validation")
  end

  # These objects are skinny wrappers for going from the AST to actual {Node} and {Field} instances.
  module Syntax
    autoload(:Call,     "graphql/syntax/call")
    autoload(:Field,    "graphql/syntax/field")
    autoload(:Query,    "graphql/syntax/query")
    autoload(:Fragment, "graphql/syntax/fragment")
    autoload(:Node,     "graphql/syntax/node")
    autoload(:Variable, "graphql/syntax/variable")
  end

  # These objects expose values
  module Types
    autoload(:BooleanType, "graphql/types/boolean_type")
    autoload(:ObjectType, "graphql/types/object_type")
    autoload(:StringType, "graphql/types/string_type")
    autoload(:NumberType, "graphql/types/number_type")
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
  # The class that this node is supposed to expose isn't defined
  class ExposesClassMissingError < Error
    def initialize(node_class)
      super("#{node_class.name} exposes #{node_class.exposes_class_names.join(", ")}, but that class wasn't found.")
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
  ["introspection", "types"].each do |preload_dir|
    full_dir = File.expand_path("../graphql/#{preload_dir}/*.rb", __FILE__)
    Dir.glob(full_dir).each { |f| require f }
  end
  # work around some dependency issue:
  Node.field.__type__(:__type__)

  def self.parse(as, string)
    parser = GraphQL::PARSER.public_send(as)
    tree = parser.parse(string)
    GraphQL::TRANSFORM.apply(tree)
  rescue Parslet::ParseFailed => error
    line, col = error.cause.source.line_and_column
    raise GraphQL::SyntaxError.new(line, col, string)
  end
end