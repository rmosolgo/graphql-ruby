# Any object can be a type as long as it implements:
#  - #fields: Hash of { String => Field } pairs
#  - #kind: one of GraphQL::TypeKinds
#  - #interfaces: Array of Interfaces
#  - #name: String
#  - #description: String
#
class GraphQL::AbstractType
  def fields; raise NotImplementedError; end
  def kind; raise NotImplementedError; end
  def interfaces; raise NotImplementedError; end
  def name; raise NotImplementedError; end
  def description; raise NotImplementedError; end
end
