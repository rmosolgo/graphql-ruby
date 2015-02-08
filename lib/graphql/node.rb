class GraphQL::Node
  attr_accessor :fields, :query
  attr_reader :target

  autoload(:FieldNode, "graphql/node/field_node.rb")
  autoload(:FieldsEdge, "graphql/node/fields_edge.rb")
  autoload(:TypeNode, "graphql/node/type_node.rb")

  def initialize(target=nil)
    @target = target
  end

  def get_field(identifier)
    field_class = self.class.find_field(identifier)
    if identifier == "cursor"
      cursor
    elsif field_class.nil?
      raise GraphQL::FieldNotDefinedError, "#{self.class.name}##{identifier} was requested, but it isn't defined."
    else
      field_class.new(query: query)
    end
  end

  def get_edge(identifier)
    field_class = self.class.find_field(identifier)
    if field_class.nil?
      raise GraphQL::FieldNotDefinedError, "#{self.class.name}##{identifier} was requested, but it isn't defined."
    else
      edge = field_class.new(query: query)
      collection_items = send_field(edge.method)
      edge_class = edge.edge_class
      node_class = edge.node_class
      edge_class.new(items: collection_items, node_class: node_class)
    end
  end

  def send_field(method_name)
    if respond_to?(method_name)
      public_send(method_name)
    elsif target.respond_to?(method_name)
      target.send(method_name)
    else
      binding.pry
      raise "Couldn't find a target for #{self.class.name}##{method_name}"
    end
  end

  def as_json
    json = {}
    fields.each do |field|
      name = field.identifier
      if field.is_a?(GraphQL::Syntax::Field)
        key_name = field.alias_name || field.identifier
        field = get_field(name)
        json[key_name] = send_field(field.method)
      elsif field.is_a?(GraphQL::Syntax::Edge)
        edge = get_edge(field.identifier)
        edge.calls = field.call_hash
        edge.fields = field.fields
        edge.query = query
        json[name] = edge.as_json
      end
    end
    json
  end

  def context
    query.context
  end

  class << self
    def fields
      @fields ||= []
    end

    def has_field?(identifier)
      !!find_field(identifier)
    end

    def find_field(identifier)
      fields.find { |f| f.const_get(:NAME) == identifier.to_s }
    end

    def desc(describe)
      @description = describe
    end

    def description
      @description || raise("#{name}.description isn't defined")
    end

    def type(type_name)
      GraphQL::TYPE_ALIASES[type_name] = self
      @node_name = type_name
    end

    def node_name
      @node_name || name.split("::").last.sub(/Node$/, '')
    end
  end


  def self.call(argument)
    raise NotImplementedError, "Implement #{name}#call(argument) to use this node as a call"
  end

  def self.field(field_name, method: nil, description: nil, type: nil)
    field_name = field_name.to_s
    raise "You already defined #{field_name}" if has_field?(field_name)
    fields << GraphQL::Field.create_class({
      name: field_name,
      owner: self,
      method: method,
      description: description
    })
  end

  def self.edges(field_name, method: nil, description: nil, edge_class_name: nil, node_class_name: nil)
    field_name = field_name.to_s
    raise "You already defined #{field_name}" if has_field?(field_name)
    fields << GraphQL::Field.create_class({
      name: field_name,
      owner: self,
      method: method,
      description: description,
      edge_class_name: edge_class_name,
      node_class_name: node_class_name,
    })
  end

  def self.cursor(field_name)
    define_method "cursor" do
      field = get_field(field_name)
      send_field(field.method).to_s
    end
  end
end