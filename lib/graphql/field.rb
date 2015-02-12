class GraphQL::Field
  attr_reader :query, :owner, :calls
  def initialize(query: nil, owner: nil, calls: [])
    @query = query
    @owner = owner
    @calls = calls
  end

  def raw_value
    owner.send(method)
  end

  def value
    finished_value
  end

  def finished_value
    @finished_value ||= apply_calls(raw_value, calls)
  end

  # instance `const_get` reaches up to class namespace
  def const_get(const_name)
    self.class.const_get(const_name)
  end

  # delegate to class constant
  ["name", "description", "edge_class_name", "node_class_name"].each do |method_name|
    define_method(method_name) do
      const_get(method_name.upcase)
    end
  end

  def method
    const_get(:METHOD) || name
  end

  def edge_class
    query.const_get(edge_class_name) || GraphQL::Edge
  end

  def node_class
    query.const_get(node_class_name) || raise("Couldn't find node class #{node_class_name} for #{self.class}")
  end

  def apply_calls(initial_value, call_array)
    val = initial_value
    call_array.each do |call|
      registered_call = self.class.find_call(call.identifier)
      if registered_call.nil?
        raise "Call not found: #{self.class.name}##{call.identifier}"
      end
      val = registered_call[:lambda].call(val, *call.arguments)
    end
    val
  end

  class << self
    def create_class(name:, owner_class:, type:, method: nil, description: nil, edge_class_name: nil, node_class_name: nil)
      if type.is_a?(Symbol)
        type = BUILT_IN_TYPES[type]
      end

      field_superclass = type || self
      new_class = Class.new(field_superclass)
      new_class.const_set :NAME, name
      new_class.const_set :OWNER_CLASS, owner_class
      new_class.const_set :METHOD, method
      new_class.const_set :DESCRIPTION , description
      new_class.const_set :EDGE_CLASS_NAME, (edge_class_name || "#{name.camelize}Edge")
      new_class.const_set :NODE_CLASS_NAME, (node_class_name || "#{name.singularize.camelize}Node")
      new_class
    end

    def to_s
      if const_defined?(:NAME)
        "<FieldClass: #{const_get(:OWNER_CLASS).name}::#{const_get(:NAME)}>"
      else
        super
      end
    end

    def field_type(field_type_name)
      @_field_type = field_type_name
    end

    def lookup_field_type
      @_field_type || superclass._field_type
    end

    def _field_type
      if self != GraphQL::Field
        lookup_field_type || raise("No type found for #{self}")
      else
        nil
      end
    end

    def type
      _field_type
    end

    def field_name
      const_get(:NAME)
    end

    def description
      const_get(:DESCRIPTION)
    end

    def calls
      @calls ||= []
    end

    def parent_calls
      superclass == Object ? [] : (superclass.calls  + superclass.parent_calls)
    end

    def all_calls
      calls + parent_calls
    end

    def find_call(name)
      all_calls.find { |c| c[:name] == name }
    end

    def call(name, lambda)
      calls << {
        name: name.to_s,
        lambda: lambda,
      }
    end
  end

  BUILT_IN_TYPES = {
    string:     GraphQL::Types::StringField,
    connection: GraphQL::Types::ConnectionField,
    number:     GraphQL::Types::NumberField,
  }
end