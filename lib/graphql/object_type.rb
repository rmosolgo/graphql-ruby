module GraphQL
  # This type exposes fields on an object.
  #
  # @example defining a type for your IMDB clone
  #   MovieType = GraphQL::ObjectType.define do
  #     name "Movie"
  #     description "A full-length film or a short film"
  #     interfaces [ProductionInterface, DurationInterface]
  #
  #     field :runtimeMinutes, !types.Int, property: :runtime_minutes
  #     field :director, PersonType
  #     field :cast, CastType
  #     field :starring, types[PersonType] do
  #       argument :limit, types.Int
  #       resolve ->(object, args, ctx) {
  #         stars = object.cast.stars
  #         args[:limit] && stars = stars.limit(args[:limit])
  #         stars
  #       }
  #      end
  #   end
  #
  class ObjectType < GraphQL::BaseType
    accepts_definitions :interfaces, :fields, :mutation, field: GraphQL::Define::AssignObjectField

    lazy_defined_attr_accessor :fields, :mutation

    # @!attribute fields
    #   @return [Hash<String => GraphQL::Field>] Map String fieldnames to their {GraphQL::Field} implementations

    # @!attribute mutation
    #   @return [GraphQL::Relay::Mutation, nil] The mutation this field was derived from, if it was derived from a mutation


    def initialize
      @fields = {}
      @dirty_interfaces = []
    end

    # @param new_interfaces [Array<GraphQL::Interface>] interfaces that this type implements
    def interfaces=(new_interfaces)
      @clean_interfaces = nil
      @dirty_interfaces = new_interfaces
    end

    def interfaces
      @clean_interfaces ||= begin
        ensure_defined
        @dirty_interfaces.map { |i_type| GraphQL::BaseType.resolve_related_type(i_type) }
      rescue
        @dirty_interfaces
      end
    end

    def kind
      GraphQL::TypeKinds::OBJECT
    end

    # @return [GraphQL::Field] The field definition for `field_name` (may be inherited from interfaces)
    def get_field(field_name)
      fields[field_name] || interface_fields[field_name]
    end

    # @return [Array<GraphQL::Field>] All fields, including ones inherited from interfaces
    def all_fields
      interface_fields.merge(self.fields).values
    end

    private

    # Create a {name => defn} hash for fields inherited from interfaces
    def interface_fields
      interfaces.reduce({}) do |memo, iface|
        memo.merge!(iface.fields)
      end
    end
  end
end
