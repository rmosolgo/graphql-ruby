# {Field}s are used to safely lookup values on {Node}s. When you define a custom field, you can access it from {Node.field}
#
# `graphql` has built-in fields for some Ruby data types:
# - `boolean`: {Types::BooleanField}
# - `number`: {Types::NumberField}
# - `string`: {Types::StringField}
#
# You can define custom fields that allow you to control how values are exposed.
# - {Field.type} defines how it can be used inside {Node.field} calls.
# - {Field.call} defines calls that can mutate the value before it is added to the response.
#
# @example
#   # For example, an `AddressField` which wraps a string but exposes address-specific information
#   class AddressField < GraphQL::Field
#     type :address
#     # ^^ now you can use it with `field.address` in node definitions
#
#     # calls can modify the value:
#     # eg, get the numbers at the beginning:
#     call :house_number, -> (prev_value) { prev_value[/^\d*/]}
#     # get everything after a space:
#     call :street_name,  -> (prev_value) { prev_value[/\s.*$/].strip }
#   end
#
#   # Then, use it in a node definition:
#   class HouseNode < GraphQL::Node
#     exposes("House")
#     # create an `AddressField` for this node called `street_address`:
#     field.address(:street_address)
#   end
#
#   # Then, use the field in queries:
#   <<QUERY
#   find_house(1) {
#     street_address,
#     street_address.house_number() as number,
#     street_address.street_name() as street,
#   }
#   QUERY
class GraphQL::Field
  attr_reader :query, :owner, :calls, :fields
  def initialize(query: nil, owner: nil, calls: [], fields: [])
    @query = query
    @owner = owner
    @calls = calls
    @fields = fields
  end

  def raw_value
    owner.send(name)
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
    # @param [Symbol] type_name the name used for getting this field from the {GraphQL::SCHEMA}.
    # Defines the name used for getting fields of this type from the schema.
    # @example
    #   # define the field with its type:
    #   class IPAddressField < GraphQL::Field
    #     type :ip_address
    #   end
    #
    #   # then, attach fields of this type to your nodes:
    #   class ServerNode < GraphQL::Field
    #     field.ip_address(:static_ip_address)
    #   end
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
    # @param [String] name the identifier for this call
    # @param [lambda] operation the transformation this call makes
    #
    # Define a call that can be made on this field.
    # The `lambda` receives arguments:
    # - 1: `previous_value` -- the value of this field
    # - *: arguments passed in the query (as strings)
    #
    # @example
    #   # upcase a string field:
    #   call :upcase, -> (prev_value) { prev_value.upcase }
    # @example
    #   # tests a number field:
    #   call :greater_than, -> (prev_value, test_value) { prev_value > test_value.to_f }
    #   # (`test_value` is passed in as a string)
    def call(name, lambda)
      _calls[name.to_s] = GraphQL::Call.new(name: name.to_s, lambda: lambda)
    end

    private

    def _calls
      @calls ||= {}
    end

  end

  type :any
end