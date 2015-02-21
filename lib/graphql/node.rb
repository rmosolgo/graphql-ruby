class GraphQL::Node
  attr_reader :syntax_fields, :query
  attr_reader :target

  def initialize(target=nil, fields:, query:)
    @target = target
    @query = query
    @syntax_fields = fields
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
    syntax_fields.each do |syntax_field|
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

  def context
    query.context
  end

  def get_field(syntax_field)
    field_class = self.class.all_fields[syntax_field.identifier]
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
      # use name to prevent autoloading Connection
      if child_class.ancestors.map(&:name).include?("GraphQL::Connection")
        GraphQL::SCHEMA.add_connection(child_class)
      else
        GraphQL::SCHEMA.add_type(child_class)
      end
    end

    def exposes(ruby_class_name)
      @ruby_class_name = ruby_class_name
      GraphQL::SCHEMA.add_type(self)
    end

    def ruby_class_name
      @ruby_class_name
    end

    def desc(describe)
      @description = describe
    end

    def description
      @description || raise("#{name}.description isn't defined")
    end

    def type(type_name)
      @type_name = type_name.to_s
      GraphQL::SCHEMA.add_type(self)
    end

    def schema_name
      @type_name || default_schema_name
    end

    def default_schema_name
      name.split("::").last.sub(/Node$/, '').underscore
    end

    def cursor(field_name)
      define_method "cursor" do
        field_class = self.class.all_fields[field_name.to_s]
        field = field_class.new(query: query, owner: self, calls: [])
        cursor = GraphQL::Types::CursorField.new(field.as_result)
        cursor.as_result
      end
    end

    def all_fields
      superclass.all_fields.merge(own_fields)
    rescue NoMethodError
      own_fields
    end

    def own_fields
      @own_fields ||= {}
    end

    def field
      @field_definer ||= GraphQL::FieldDefiner.new(self)
    end

    def remove_field(field_name)
      own_fields.delete(field_name.to_s)
    end
  end
end