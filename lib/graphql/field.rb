class GraphQL::Field
  attr_reader :query, :owner, :calls, :fields
  def initialize(query: nil, owner: nil, calls: [], fields: [])
    @query = query
    @owner = owner
    @calls = calls
    @fields = fields
  end

  def raw_value
    owner.send(method)
  end

  def as_result
    finished_value
  end

  def finished_value
    @finished_value ||= begin
      val = raw_value
      calls.each do |call|
        registered_call = self.class.calls[call.identifier]
        if registered_call.nil?
          raise "Call not found: #{self.class.name}##{call.identifier}"
        end
        val = registered_call.lambda.call(val, *call.arguments)
      end
      val
    end
  end

  # instance `const_get` reaches up to class namespace
  def const_get(const_name)
    self.class.const_get(const_name)
  rescue
    nil
  end

  # delegate to class constant
  ["name", "description"].each do |method_name|
    define_method(method_name) do
      const_get(method_name.upcase)
    end
  end

  def method; name; end

  class << self
    def inherited(child_class)
      GraphQL::SCHEMA.add_field(child_class)
    end

    def create_class(name:, owner_class:, type:, description: nil, connection_class_name: nil, node_class_name: nil)
      if type.is_a?(Symbol)
        type = GraphQL::SCHEMA.get_field(type)
      end

      field_superclass = type || self
      new_class = Class.new(field_superclass)
      new_class.const_set :NAME, name
      new_class.const_set :OWNER_CLASS, owner_class
      new_class.const_set :DESCRIPTION , description
      new_class.const_set :CONNECTION_CLASS_NAME, connection_class_name
      new_class.const_set :NODE_CLASS_NAME, node_class_name
      new_class
    end

    def to_s
      if const_defined?(:NAME)
        "<FieldClass: #{const_get(:OWNER_CLASS).name}::#{const_get(:NAME)}>"
      else
        super
      end
    end

    def type(value_type_name)
      @value_type = value_type_name.to_s
      GraphQL::SCHEMA.add_field(self)
    end

    def value_type
      @value_type || superclass.value_type
    end

    def schema_name
      @value_type || (name.present? ? default_schema_name : nil)
    end

    def default_schema_name
      name.split("::").last.sub(/Field$/, '').underscore
    end

    def field_name
      const_get(:NAME)
    end

    def description
      const_get(:DESCRIPTION)
    end

    def calls
      superclass.calls.merge(_calls)
    rescue NoMethodError
      {}
    end

    def _calls
      @calls ||= {}
    end

    def call(name, lambda)
      _calls[name.to_s] = GraphQL::Call.new(name: name.to_s, lambda: lambda)
    end
  end

  type :any
end