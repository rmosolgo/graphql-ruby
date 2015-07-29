# These are valid values for a type's `fields` hash.
#
# You can also use {FieldDefiner#build} to create fields.
#
# @example creating a field
#   name_field = GraphQL::Field.new do |f, types|
#     f.name("Name")
#     f.type(!types.String)
#     f.description("The name of this thing")
#     f.resolve -> (object, arguments, context) { object.name }
#   end
#
class GraphQL::Field
  extend GraphQL::Definable
  attr_definable(:arguments, :deprecation_reason, :name, :description, :type)

  def initialize
    @arguments = {}
    @resolve_proc = -> (o, a, c) { GraphQL::Query::DEFAULT_RESOLVE }
    yield(self, GraphQL::TypeDefiner.instance, GraphQL::FieldDefiner.instance, GraphQL::ArgumentDefiner.instance)
  end

  def arguments(new_arguments=nil)
    if !new_arguments.nil?
      self.arguments=(new_arguments)
    end
    @arguments
  end

  # Define the arguments for this field using {StringNamedHash}
  def arguments=(new_arguments)
    @arguments = GraphQL::StringNamedHash.new(new_arguments).to_h
  end

  # @overload resolve(definition_proc)
  #   Define this field to return a value with `definition_proc`
  #   @example defining the resolve method
  #     field.resolve -> (obj, args, ctx) { obj.get_value }
  #   @param definition_proc [Proc] The proc to evaluate to get a value
  #
  # @overload resolve(object, arguments, context)
  #   Get a value for this field
  #   @example resolving a field value
  #     field.resolve(obj, args, ctx)
  #
  #   @param object [Object] The object this field belongs to
  #   @param arguments [Hash] Arguments declared in the query
  #   @param context [GraphQL::Query::Context]
  def resolve(proc_or_object, arguments=nil, context=nil)
    if arguments.nil? && context.nil?
      @resolve_proc = proc_or_object
    else
      @resolve_proc.call(proc_or_object, arguments, context)
    end
  end

  # @overload type(return_type)
  #   Define the return type for this field
  #   @param return_type [GraphQL::ObjectType, GraphQL::ScalarType] The type this field returns
  #
  # @overload type(return_type_proc)
  #   Wrap the return type in a proc,which will cause the type to be lazy-evaled,
  #
  #   That's nice if you have load-order issues.
  #   @example lazy-evaled return type
  #      field.type(-> { MyCircularDependentType })
  #   @param return_type_proc [Proc] A proc which returns the return type for this field
  def type(type_or_proc=nil)
    if !type_or_proc.nil?
      @type = type_or_proc
    elsif @type.is_a?(Proc)
      # lazy-eval it
      @type = @type.call
    end
    @type
  end
end
