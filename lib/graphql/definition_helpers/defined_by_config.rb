# Provide a two-step definition process.
#
# 1. Use a config object to gather definitions
# 2. Transfer definitions to an actual instance of an object
#
module GraphQL::DefinitionHelpers::DefinedByConfig
  def self.included(base)
    base.extend(ClassMethods)
  end

  # This object is `instance_eval`'d  when defining _any_ object in the schema.
  # Then, the applicable properties of this object are transfered to the given instance.
  class DefinitionConfig
    def self.attr_definable(*names)
      attr_accessor(*names)
      names.each do |name|
        ivar_name = "@#{name}".to_sym
        define_method(name) do |new_value=nil|
          new_value && self.instance_variable_set(ivar_name, new_value)
          instance_variable_get(ivar_name)
        end
      end
    end

    attr_definable :name, :description,
      :interfaces, # object
      :deprecation_reason, # field
      :type, # field / argument
      :resolve, # field / directive
      :resolve_type, # interface / union
      :possible_types, # interface / union
      :default_value, # argument
      :on, # directive
      :coerce, #scalar
      :coerce_input, #scalar
      :coerce_result #scalar

    attr_reader :fields, :input_fields, :arguments, :values

    def initialize
      @interfaces = []
      @possible_types = []
      @on = []
      @fields = {}
      @arguments = {}
      @values = []
      @input_fields = {}
    end

    def types
      GraphQL::DefinitionHelpers::TypeDefiner.instance
    end

    def field(name, type = nil, desc = nil, field: nil, property: nil, &block)
      if block_given?
        field = GraphQL::Field.define(&block)
      else
        field ||= GraphQL::Field.new
      end
      type && field.type = type
      desc && field.description = desc
      property && field.resolve = -> (t,a,c) { t.public_send(property)}
      field.name ||= name.to_s
      fields[name.to_s] = field
    end

    # For EnumType
    def value(name, desc = nil, deprecation_reason: nil, value: name)
      values << GraphQL::EnumType::EnumValue.new(name: name, description: desc, deprecation_reason: deprecation_reason, value: value)
    end

    # For InputObjectType
    def input_field(name, type = nil, desc = nil, default_value: nil, &block)
      argument = if block_given?
        GraphQL::Argument.define(&block)
      else
        GraphQL::Argument.new
      end
      argument.name = name
      type && argument.type = type
      desc && argument.description = desc
      default_value && argument.default_value = default_value
      input_fields[name.to_s] = argument
    end

    def argument(name, type, description = nil, default_value: nil)
       argument = GraphQL::Argument.new
       argument.name = name.to_s
       argument.type = type
       argument.description = description
       argument.default_value = default_value
       @arguments[name.to_s] = argument
     end

    def to_instance(object, attributes)
      attributes.each do |attr_name|
        configured_value = self.public_send(attr_name)
        object.public_send("#{attr_name}=", configured_value)
      end
      object
    end
  end

  module ClassMethods
    # Pass the block to this class's `DefinitionConfig`,
    # The return the result of {DefinitionConfig#to_instance}
    def define(&block)
      config = DefinitionConfig.new
      block && config.instance_eval(&block)
      config.to_instance(self.new, @defined_attrs)
    end

    def defined_by_config(*defined_attrs)
      @defined_attrs ||= []
      @defined_attrs += defined_attrs
    end
  end
end
