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
#       arguments :limit, types.Int
#       resolve -> (object, args, ctx) {
#         stars = object.cast.stars
#         args[:limit] && stars = stars.limit(args[:limit])
#         stars
#       }
#      end
#   end
#
class GraphQL::ObjectType < GraphQL::BaseType
  accepts_definitions :interfaces, field: GraphQL::Define::AssignObjectField
  attr_accessor :name, :description, :interfaces

  # @return [Hash<String, GraphQL::Field>] Map String fieldnames to their {GraphQL::Field} implementations
  attr_accessor :fields

  def initialize
    @fields = {}
    @interfaces = []
  end

  # Shovel this type into each interface's `possible_types` array.
  #
  # @param new_interfaces [Array<GraphQL::Interface>] interfaces that this type implements
  def interfaces=(new_interfaces)
    @interfaces ||= []
    (@interfaces - new_interfaces).each { |i| i.possible_types.delete(self) }
    (new_interfaces - @interfaces).each { |i| i.possible_types << self }
    @interfaces = new_interfaces
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

  def input_type
    tmp_name = self.name
    tmp_fields = self.fields
    @input_type ||= GraphQL::InputObjectType.define do
      name tmp_name + 'Input'
      description 'Automatically generated input type'
      tmp_fields.each do |name, field|
        field_type = field.type
        if field_type.is_a? GraphQL::ObjectType
          field_type = field_type.input_type
        elsif field_type.is_a? GraphQL::ListType
          if field_type.of_type.is_a? GraphQL::ObjectType
            field_type = GraphQL::ListType.new(of_type: field_type.of_type.input_type)
          end
        end
        input_field name, field_type
      end
    end
  end

  private

  # Create a {name => defn} hash for fields inherited from interfaces
  def interface_fields
    interfaces.reduce({}) do |memo, iface|
      memo.merge!(iface.fields)
    end
  end
end
