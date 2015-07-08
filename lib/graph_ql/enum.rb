class GraphQL::Enum
  attr_reader :name
  def initialize(name, values)
    @name = name
    @values = values.reduce({}) { |memo, n|  memo[n] = n; memo}
  end

  def [](val)
    @values[val]
  end

  def kind
    GraphQL::TypeKinds::ENUM
  end
end
