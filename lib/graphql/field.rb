# {Field}s belong to {ObjectType}s and {InterfaceType}s.
#
# They're usually created with the `field` helper.
#
#
# @example creating a field
#   GraphQL::ObjectType.define do
#     field :name, types.String, "The name of this thing "
#   end
#
# @example creating a field that accesses a different property on the object
#   GraphQL::ObjectType.define do
#     # use the `property` option:
#     field :firstName, types.String, property: :first_name
#   end
#
# @example defining a field, then attaching it to a type
#   name_field = GraphQL::Field.define do
#     name("Name")
#     type(!types.String)
#     description("The name of this thing")
#     resolve -> (object, arguments, context) { object.name }
#   end
#
#   NamedType = GraphQL::ObjectType.define do
#     # use the `field` option:
#     field :name, field: name_field
#   end
#
class GraphQL::Field
  DEFAULT_RESOLVE = -> (o, a, c) { GraphQL::Query::DEFAULT_RESOLVE }
  include GraphQL::DefinitionHelpers::DefinedByConfig
  attr_accessor :arguments, :deprecation_reason, :name, :description, :type

  class DefinitionConfig
    extend GraphQL::DefinitionHelpers::Definable
    attr_definable :name, :description, :type, :deprecation_reason, :resolve
    def initialize
      @arguments = {}
    end

    def types
      GraphQL::DefinitionHelpers::TypeDefiner.instance
    end

    def argument(name, type, description = nil, default_value: nil)
      @arguments[name.to_s] = GraphQL::Argument.new(
        name: name.to_s,
        type: type,
        description: description,
        default_value: nil,
      )
    end

    def to_instance
      object = GraphQL::Field.new
      object.name = name
      object.type = type
      object.description = description
      object.deprecation_reason = deprecation_reason
      object.resolve = resolve
      object.arguments = @arguments
      object
    end
  end

  def initialize
    @arguments = {}
    @resolve_proc = DEFAULT_RESOLVE
  end

  def arguments(new_arguments=nil)
    if !new_arguments.nil?
      self.arguments=(new_arguments)
    end
    @arguments
  end

  # Define the arguments for this field using {StringNamedHash}
  def arguments=(new_arguments)
    @arguments = GraphQL::DefinitionHelpers::StringNamedHash.new(new_arguments).to_h
  end

  # Get a value for this field
  # @example resolving a field value
  #   field.resolve(obj, args, ctx)
  #
  # @param object [Object] The object this field belongs to
  # @param arguments [Hash] Arguments declared in the query
  # @param context [GraphQL::Query::Context]
  def resolve(object, arguments, context)
    @resolve_proc.call(object, arguments, context)
  end

  def resolve=(resolve_proc)
    @resolve_proc = resolve_proc || DEFAULT_RESOLVE
  end

  # Get the return type for this field.
  def type
    if @type.is_a?(Proc)
      # lazy-eval it
      @type = @type.call
    end
    @type
  end

  def to_s
    "<Field: #{name || "not-named"}>"
  end
end
