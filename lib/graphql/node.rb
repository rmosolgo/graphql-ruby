class GraphQL::Node
  include GraphQL::Fieldable
  attr_accessor :fields, :query
  attr_reader :target

  def initialize(target=nil)
    @target = target
  end

  def method_missing(method_name, *args, &block)
    if target.respond_to?(method_name)
      target.public_send(method_name, *args, &block)
    else
      super
    end
  end

  def as_json
    json = {}
    fields.each do |field|
      name = field.identifier
      if field.is_a?(GraphQL::Syntax::Field)
        key_name = field.alias_name || field.identifier
        field = get_field(field)
        json[key_name] = field.value
      elsif field.is_a?(GraphQL::Syntax::Edge)
        edge = get_edge(field)
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

  def self.cursor(field_name)
    define_method "cursor" do
      field_class = self.class.find_field(field_name)
      field = field_class.new(query: query, owner: self, calls: [])
      field.value.to_s
    end
  end
end