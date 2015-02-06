class GraphQL::Node
  attr_accessor :fields, :query

  def initialize(target=nil)
    # DONT EXPOSE Node#target! otherwise you might be able to access it
    @target = target
  end

  def safe_send(identifier)
    if respond_to?(identifier)
      public_send(identifier)
    else
      raise GraphQL::FieldNotDefinedError, "#{self.class.name}##{identifier} was requested, but it isn't defined."
    end
  end

  def as_json
    json = {}
    fields.each do |field|
      name = field.identifier
      if field.is_a?(GraphQL::Syntax::Field)
        json[name] = safe_send(name)
      elsif field.is_a?(GraphQL::Syntax::Edge)
        edge = safe_send(field.identifier)
        edge.calls = field.call_hash
        edge.fields = field.fields
        edge.query = query
        json[name] = edge.as_json
      end
    end
    json
  end


  def self.call(argument)
    raise NotImplementedError, "Implement #{name}#call(argument) to use this node as a call"
  end

  def self.field_reader(*field_names)
    field_names.each do |field_name|
      define_method(field_name) do
        @target.public_send(field_name)
      end
    end
  end

  def self.edges(field_name, edge_class_name: nil, node_class_name: nil)
    define_method(field_name) do
      collection_items = @target.send(field_name)
      edge_class = edge_class_name.nil? ? query.get_edge(field_name.to_s) : Object.const_get(edge_class_name)
      node_class = node_class_name.nil? ? query.get_node(field_name.to_s.singularize) : Object.const_get(node_class_name)
      collection = edge_class.new(items: collection_items, node_class: node_class)
    end
  end


  def self.cursor(field_name)
    define_method "cursor" do
      safe_send(field_name).to_s
    end
  end
end