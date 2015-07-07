require "active_support/core_ext/object/blank"
require "active_support/core_ext/string/inflections"
require "active_support/dependencies/autoload"
require "json"
require "parslet"

module GraphQL
  extend ActiveSupport::Autoload
  autoload(:Interface)
  autoload(:Parser)
  autoload(:Query)
  autoload(:Schema)
  autoload(:Syntax)
  autoload(:Type)
  autoload(:VERSION)

  autoload_under "fields" do
    autoload(:AbstractField)
    autoload(:AccessField)
    autoload(:AccessFieldDefiner)
    autoload(:NonNullField)
  end

  autoload_under "scalars" do
    autoload(:ScalarType)
    autoload(:StringType)
  end

  # Singleton {Parser::Parser} instance
  PARSER = Parser::Parser.new
  # Singleton {Parser::Transform} instance
  TRANSFORM = Parser::Transform.new

  def self.parse(string)
    tree = GraphQL::PARSER.parse(string)
    GraphQL::TRANSFORM.apply(tree)
  rescue Parslet::ParseFailed => error
    line, col = error.cause.source.line_and_column
    raise GraphQL::SyntaxError.new(line, col, string)
  end


  module Definable
    def attr_definable(*names)
      names.each do |name|
        ivar_name = "@#{name}".to_sym
        define_singleton_method(name) do |new_value=nil|
          new_value && self.instance_variable_set(ivar_name, new_value)
          instance_variable_get(ivar_name)
        end
      end
    end
  end
end
