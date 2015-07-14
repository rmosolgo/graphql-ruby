class GraphQL::Union
  include GraphQL::NonNullWithBang
  attr_reader :name, :description, :possible_types
  def initialize(name, desc, types)
    @name = name
    @description = desc
    @possible_types = types
  end

  def kind; GraphQL::TypeKinds::UNION; end

  def include?(type)
    possible_types.include?(type)
  end

  # Find a type in this union for a given object.
  # Reimplement if needed
  def resolve_type(object)
    type_name = object.class.name
    possible_types.find {|t| t.name == type_name}
  end

  def to_s
    "<GraphQL::Union #{name}>"
  end
end
