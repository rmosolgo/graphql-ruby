# Each {Node} has {FieldMapping}s that are used to look up fields at query-time
class GraphQL::FieldMapping
  attr_reader :type, :name
  def initialize(name:, type:)
    @name = name
    @type = type.to_s
  end

  def field_class
    GraphQL::SCHEMA.get_field(type)
  end

  def to_field(new_params={})
    field_params = {
        name: name,
      }.merge(new_params)
    field_class.new(field_params)
  end
end