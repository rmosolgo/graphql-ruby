module GraphQL
  # {Field}s belong to {ObjectType}s and {InterfaceType}s.
  #
  # They're usually created with the `field` helper. If you create it by hand, make sure {#name} is a String.
  #
  #
  # @example creating a field
  #   GraphQL::ObjectType.define do
  #     field :name, types.String, "The name of this thing "
  #   end
  #
  # @example handling a circular reference
  #   # If the field's type isn't defined yet, you have two options:
  #
  #   GraphQL::ObjectType.define do
  #     # If you pass a Proc, it will be evaluated at schema build-time
  #     field :city, -> { CityType }
  #     # If you pass a String, it will be looked up in the global namespace at schema build-time
  #     field :country, "CountryType"
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
  class Field
    include GraphQL::Define::InstanceDefinable
    accepts_definitions :name, :description, :resolve, :type, :property, :deprecation_reason, argument: GraphQL::Define::AssignArgument

    attr_accessor :deprecation_reason, :name, :description, :type, :property
    attr_reader :resolve_proc

    # @return [String] The name of this field on its {GraphQL::ObjectType} (or {GraphQL::InterfaceType})
    attr_reader :name

    # @return [Hash<String, GraphQL::Argument>] Map String argument names to their {GraphQL::Argument} implementations
    attr_accessor :arguments

    def initialize
      @arguments = {}
      @resolve_proc = build_default_resolver
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
      @resolve_proc = resolve_proc || build_default_resolver
    end

    # Get the return type for this field.
    def type
      case @type
      when Proc
        # lazy-eval it
        @type = @type.call
      when String
        # Get a constant by this name
        @type = Object.const_get(@type)
      else
        @type
      end
    end

    # You can only set a field's name _once_ -- this to prevent
    # passing the same {Field} to multiple `.field` calls.
    #
    # This is important because {#name} may be used by {#resolve}.
    def name=(new_name)
      if !new_name.is_a?(String)
        raise ArgumentError.new("GraphQL field names must be strings; cannot use #{new_name.inspect} (#{new_name.class.name}) as a field name.") unless new_name.is_a?(String)
      elsif @name.nil?
        @name = new_name
      else
        raise("Can't rename an already-named field. (Tried to rename \"#{@name}\" to \"#{new_name}\".) If you're passing a field with the `field:` argument, make sure it's an unused instance of GraphQL::Field.")
      end
    end

    def to_s
      "<Field: #{name || "not-named"}>"
    end

    private

    def build_default_resolver
      -> (obj, args, ctx) do
        resolve_method = self.property || self.name
        obj.public_send(resolve_method)
      end
    end
  end
end
