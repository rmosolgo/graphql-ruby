require "active_support/core_ext/object/blank"
require "active_support/core_ext/string/inflections"
require "active_support/dependencies/autoload"
require "json"
require "parslet"

module GraphQL
  extend ActiveSupport::Autoload
  autoload(:Enum)
  autoload(:Interface)
  autoload(:Parser)
  autoload(:Query)
  autoload(:Repl)
  autoload(:Schema)
  autoload(:TypeKinds)
  autoload(:Union)
  autoload(:Validator)
  autoload(:VERSION)

  autoload_under "fields" do
    autoload(:AbstractField)
    autoload(:AccessField)
    autoload(:Field)
  end

  autoload_under "introspection" do
    autoload(:FieldType)
    autoload(:FieldsField)
    autoload(:InputValueType)
    autoload(:InputFieldsField)
    autoload(:OfTypeField)
    autoload(:PossibleTypesField)
    autoload(:SchemaType)
    autoload(:TypeKindEnum)
    autoload(:TypeType)
  end

  autoload_under "parser" do
    autoload(:Nodes)
    autoload(:Parser)
    autoload(:Transform)
    autoload(:Visitor)
  end

  autoload_under "types" do
    autoload(:AbstractType)
    autoload(:BOOLEAN_TYPE)
    autoload(:ScalarType)
    autoload(:FLOAT_TYPE)
    autoload(:InputObjectType)
    autoload(:InputValue)
    autoload(:INT_TYPE)
    autoload(:ListType)
    autoload(:NonNullType)
    autoload(:NonNullWithBang)
    autoload(:ObjectType)
    autoload(:STRING_TYPE)
    autoload(:TypeDefiner)
  end

  module Validations
    extend ActiveSupport::Autoload
    autoload(:FieldsWillMerge)
    autoload(:FragmentsAreUsed)
    autoload(:FieldsAreDefinedOnType)
  end

  PARSER = Parser.new
  TRANSFORM = Transform.new

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
end
