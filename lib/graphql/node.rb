class GraphQL::Node
  include GraphQL::Fieldable
  attr_reader :fields, :query
  attr_reader :target

  def initialize(target=nil, fields:, query:)
    @target = target
    @query = query
    @fields = fields
  end

  def method_missing(method_name, *args, &block)
    if target.respond_to?(method_name)
      target.public_send(method_name, *args, &block)
    else
      super
    end
  end

  def as_result
    json = {}
    fields.each do |syntax_field|
      key_name = syntax_field.alias_name || syntax_field.identifier
      if key_name == 'node'
        clone_node = self.class.new(target, fields: syntax_field.fields, query: query)
        json[key_name] = clone_node.as_result
      elsif key_name == 'cursor'
        json[key_name] = cursor
      else
        field = get_field(syntax_field)
        json[key_name] = field.as_result
      end
    end
    json
  end

  def as_json
    as_result
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


    def call(argument)
      raise NotImplementedError, "Implement #{name}#call(argument) to use this node as a call"
    end

    def cursor(field_name)
      define_method "cursor" do
        field_class = self.class.find_field(field_name)
        field = field_class.new(query: query, owner: self, calls: [])
        cursor = GraphQL::Types::CursorField.new(field.as_result)
        cursor.as_result
      end
    end
  end
end