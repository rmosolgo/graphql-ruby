# Given an object, a type name (from the query) and a type object,
# Return the type that should be used for `object`
# or Return `nil` if it's a mismatch
class GraphQL::Query::TypeResolver
  attr_reader :type
  def initialize(target, child_type, parent_type)
    @type = if child_type.nil?
      nil
    elsif parent_type.kind.union?
      parent_type.resolve_type(target)
    elsif child_type.kind.union? && child_type.include?(parent_type)
      parent_type
    elsif child_type.kind.interface?
      child_type.resolve_type(target)
    elsif child_type == parent_type
      parent_type
    else
      nil
    end
  end
end
