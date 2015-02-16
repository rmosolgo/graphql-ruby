class GraphQL::Node
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

  def get_field(syntax_field)
    field_class = self.class.find_field(syntax_field.identifier)
    if syntax_field.identifier == "cursor"
      cursor
    elsif field_class.nil?
      raise GraphQL::FieldNotDefinedError.new(self.class.name, syntax_field.identifier)
    else
      field_class.new(
        query: query,
        owner: self,
        calls: syntax_field.calls,
        fields: syntax_field.fields,
      )
    end
  end

  class << self
    def inherited(child_class)
      if child_class.ancestors.include?(GraphQL::Connection)
        return
      else
        GraphQL::SCHEMA.add_node(child_class)
      end
    end

    def desc(describe)
      @description = describe
    end

    def description
      @description || raise("#{name}.description isn't defined")
    end

    def type(type_name)
      @node_name = type_name
    end

    def schema_name
      @node_name || name.split("::").last.sub(/Node$/, '').underscore
    end

    def cursor(field_name)
      define_method "cursor" do
        field_class = self.class.find_field(field_name)
        field = field_class.new(query: query, owner: self, calls: [])
        cursor = GraphQL::Types::CursorField.new(field.as_result)
        cursor.as_result
      end
    end

    def fields
      @fields ||= []
    end

    def parent_fields
      superclass.fields + superclass.parent_fields
    rescue NoMethodError
      []
    end

    def all_fields
      fields + parent_fields
    end

    def has_field?(identifier)
      !!find_field(identifier)
    end

    def find_field(identifier)
      all_fields.find { |f| f.const_get(:NAME) == identifier.to_s }
    end

    def field(field_name, type: nil, method: nil, description: nil, connection_class_name: nil, node_class_name: nil)
      field_name = field_name.to_s
      field_class = GraphQL::Field.create_class({
        name: field_name,
        type: type,
        owner_class: self,
        method: method,
        description: description,
        connection_class_name: connection_class_name,
        node_class_name: node_class_name,
      })
      field_class_name = field_name.camelize + "Field"
      self.const_set(field_class_name, field_class)
      fields << field_class
    end
  end
end