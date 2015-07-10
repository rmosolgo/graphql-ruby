# Given an object, a type name (from the query) and a type object,
# Return the type that should be used for `object`
# or Return `nil` if it's a mismatch
class GraphQL::Query::TypeResolver
  attr_reader :type
  def initialize(target, child_type, parent_type)
    @type = if child_type.nil?
      nil
    elsif GraphQL::TypeKinds::UNION == parent_type.kind
      parent_type.resolve_type(target)
    elsif GraphQL::TypeKinds::INTERFACE == child_type.kind
      child_type.resolve_type(target)
    elsif child_type == parent_type
      parent_type
    else
      nil
    end
  end
end
