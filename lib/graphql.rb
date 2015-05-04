require "active_support/core_ext/object/blank"
require "active_support/core_ext/string/inflections"
require "active_support/dependencies/autoload"
require "json"
require "parslet"

module GraphQL
  extend ActiveSupport::Autoload
  autoload(:Call)
  autoload(:Connection)
  autoload(:FieldDefiner)
  autoload(:Field)
  autoload(:Node)
  autoload(:Query)
  autoload(:RootCall)
  autoload(:RootCallArgument)
  autoload(:RootCallArgumentDefiner)
  autoload(:VERSION)

  # These objects are used for introspections (eg, responding to `schema()` calls).
  module Introspection
    extend ActiveSupport::Autoload
    autoload(:CallType)
    autoload(:Connection)
    autoload(:FieldType)
    autoload(:RootCallArgumentNode)
    autoload(:RootCallType)
    autoload(:SchemaCall)
    autoload(:SchemaType)
    autoload(:TypeCall)
    autoload(:TypeType)
  end

  # These objects are singletons used to parse queries
  module Parser
    extend ActiveSupport::Autoload
    autoload(:Parser)
    autoload(:Transform)
  end

  # These objects are used to track the schema of the graph
  module Schema
    extend ActiveSupport::Autoload
    autoload(:ALL)
    autoload(:Schema)
    autoload(:SchemaValidation)
  end

  # These objects are skinny wrappers for going from the AST to actual {Node} and {Field} instances.
  module Syntax
    extend ActiveSupport::Autoload
    autoload(:Call)
    autoload(:Field)
    autoload(:Query)
    autoload(:Fragment)
    autoload(:Node)
    autoload(:Variable)
  end

  # These objects expose values
  module Types
    extend ActiveSupport::Autoload
    autoload(:DateType)
    autoload(:DateTimeType)
    autoload(:BooleanType)
    autoload(:ObjectType)
    autoload(:StringType)
    autoload(:TimeType)
    autoload(:NumberType)
  end

  autoload_under "errors" do
    autoload(:CallNotDefinedError)
    autoload(:Error)
    autoload(:ExposesClassMissingError)
    autoload(:FieldNotDefinedError)
    autoload(:FieldNotImplementedError)
    autoload(:NodeNotDefinedError)
    autoload(:RootCallArgumentError)
    autoload(:RootCallNotDefinedError)
    autoload(:SyntaxError)
  end

  autoload_under "testing" do
    autoload(:TestCall)
    autoload(:TestCallChain)
    autoload(:TestNode)
  end

  # Singleton {Parser::Parser} instance
  PARSER = Parser::Parser.new
  # This singleton contains all defined nodes and fields.
  SCHEMA = Schema::Schema.instance
  # Singleton {Parser::Transform} instance
  TRANSFORM = Parser::Transform.new
  # preload these so they're in SCHEMA
  ["introspection", "types"].each do |preload_dir|
    full_dir = File.expand_path("../graph_ql/#{preload_dir}/*.rb", __FILE__)
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