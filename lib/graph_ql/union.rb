class GraphQL::Union
  attr_reader :name
  def initialize(name, types)
    if types.length < 2
      raise ArgumentError, "Union #{name} must be defined with 2 or more types, not #{types.length}"
    end

    non_object_types = types.select {|t| t.kind != GraphQL::TypeKinds::OBJECT}
    if non_object_types.any?
      types_string = non_object_types.map{|t| "#{t.name} #{t.kind}"}.join(", ")
      raise ArgumentError, "Unions can only consist of Object types, but #{name} non-object types: #{types_string}"
    end

    @name = name
    @types = types
  end

  def kind; GraphQL::TypeKinds::UNION; end

  def include?(type)
    @types.include?(type)
  end
end
