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
  autoload(:Introspection)
  autoload(:Node)
  autoload(:Parser)
  autoload(:Query)
  autoload(:RootCall)
  autoload(:RootCallArgument)
  autoload(:RootCallArgumentDefiner)
  autoload(:Schema)
  autoload(:Syntax)
  autoload(:Types)
  autoload(:VERSION)

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
  Introspection.eager_load!
  Types.eager_load!

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