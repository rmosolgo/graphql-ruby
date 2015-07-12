class GraphQL::Union
  include GraphQL::NonNullWithBang
  attr_reader :name, :possible_types
  def initialize(name, types)
    @name = name
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
    "<GraphQL::Union #{name} [#{possible_types.map(&:name).join(", ")}]>"
  end
end
