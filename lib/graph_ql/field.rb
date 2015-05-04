# Each {Node} has {Field}s that are used to look up connected nodes at query-time
class GraphQL::Field
  attr_reader :type, :name
  def initialize(name:, type:)
    @name = name
    @type = type.to_s
  end

  def type_class
    GraphQL::SCHEMA.get_type(type)
  end
end