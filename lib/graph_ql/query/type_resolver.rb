# Given an object, a type name (from the query) and a type object,
# Return the type that should be used for `object`
# or Return `nil` if it's a mismatch
class GraphQL::Query::TypeResolver
  attr_reader :type
  def initialize(target, type_name, defined_type)
    @type = if defined_type.kind == GraphQL::TypeKinds::UNION
      defined_type.resolve_type(target)
    elsif type_name == defined_type.name
      defined_type
    else
      nil
    end
  end
end
