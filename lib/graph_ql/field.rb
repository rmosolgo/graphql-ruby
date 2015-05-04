# Each {Node} has {Field}s that are used to look up connected nodes at query-time
class GraphQL::Field
  attr_reader :type, :name, :description
  def initialize(name:, type:, description:)
    @name = name
    @type = type
    @description = description
  end

  def type_class
    GraphQL::SCHEMA.get_type(type)
  end
end