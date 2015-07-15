require 'singleton'
class GraphQL::TypeDefiner
  include Singleton

  def Int; GraphQL::INT_TYPE; end
  def String; GraphQL::STRING_TYPE; end
  def Float; GraphQL::FLOAT_TYPE; end
  def Boolean; GraphQL::BOOLEAN_TYPE; end

  def [](type)
    GraphQL::ListType.new(of_type: type)
  end
end
