class GraphQL::Field
  attr_reader :query
  def initialize(query: nil)
    @query = query
  end

  # instance `const_get` reaches up to class namespace
  def const_get(const_name)
    self.class.const_get(const_name)
  end

  ["name", "description", "edge_class_name", "node_class_name"].each do |method_name|
    define_method(method_name) do
      const_get(method_name.upcase)
    end
  end

  def method
    const_get(:METHOD) || name
  end

  def edge_class
   edge_class_name.present? ? Object.const_get(edge_class_name) : query.get_edge(name)
  end

  def node_class
    node_class_name.present? ? Object.const_get(node_class_name) : query.get_node(name.singularize)
  end

  def self.create_class(name:, owner:, method: nil, description: nil, edge_class_name: nil, node_class_name: nil)
    new_class = Class.new(self)
    new_class.const_set :NAME, name
    new_class.const_set :OWNER, owner
    new_class.const_set :METHOD, method
    new_class.const_set :DESCRIPTION , description
    new_class.const_set :EDGE_CLASS_NAME, edge_class_name
    new_class.const_set :NODE_CLASS_NAME, node_class_name
    new_class
  end

  def self.to_s
    if const_defined?(:NAME)
      "<FieldClass: #{const_get(:OWNER).name}::#{const_get(:NAME)}>"
    else
      super
    end
  end
end