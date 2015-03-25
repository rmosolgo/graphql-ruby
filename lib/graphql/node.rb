# Node is the base class for your GraphQL nodes.
# It's essentially a delegator that only delegates methods you whitelist with {.field}.
# To use it:
#
# - Extend `GraphQL::Node`
# - Declare what this node will wrap with {.exposes}
# - Declare fields with {.field}
#
# @example
#   class PostNode < GraphQL::Node
#     exposes('Post')
#
#     cursor(:id)
#
#     field.number(:id)
#     field.string(:title)
#     field.string(:content)
#     field.connection(:comments)
#   end
#

class GraphQL::Node
  # The object wrapped by this `Node`, _before_ calls are applied
  attr_reader :original_target
  # The object wrapped by this `Node`, _after_ calls are applied
  attr_reader :target
  # Fields parsed from the query string
  attr_reader :syntax_fields
  # The query to which this `Node` belongs. Used for accessing its {Query#context}.
  attr_reader :query

  def initialize(target=nil, fields:, query:, calls: [])
    @query = query
    @calls = calls
    @syntax_fields = fields
    @original_target = target
    @target = apply_calls(target)
  end

  # If the target responds to `method_name`, send it to target.
  def method_missing(method_name, *args, &block)
    if target.respond_to?(method_name)
      target.public_send(method_name, *args, &block)
    else
      super
    end
  end

  # Looks up {#syntax_fields} against this node and returns the results
  def as_result
    @as_result ||= begin
      json = {}
      syntax_fields.each do |syntax_field|
        key_name = syntax_field.alias_name || syntax_field.identifier
        if key_name == 'node'
          clone_node = self.class.new(target, fields: syntax_field.fields, query: query, calls: syntax_field.calls)
          json[key_name] = clone_node.as_result
        elsif key_name == 'cursor'
          json[key_name] = cursor
        elsif key_name[0] == "$"
          fragment = query.fragments[key_name]
          # execute the fragment and merge it into this result
          clone_node = self.class.new(target, fields: fragment.fields, query: query, calls: @calls)
          json.merge!(clone_node.as_result)
        else
          field = get_field(syntax_field)
          new_target = public_send(field.name)
          new_node = field.type_class.new(new_target, fields: syntax_field.fields, query: query, calls: syntax_field.calls)
          json[key_name] = new_node.as_result
        end
      end
      json
    end
  end

  # The object passed to {Query#initialize} as `context`.
  def context
    query.context
  end

  def __type__
    self.class
  end

  def apply_calls(value)
    finished_value(value)
  end

  def finished_value(raw_value)
    @finished_value ||= begin
      val = raw_value
      @calls.each do |call|
        registered_call = self.class.calls[call.identifier]
        if registered_call.nil?
          raise "Call not found: #{self.class.name}##{call.identifier}"
        end
        val = registered_call.lambda.call(val, *call.arguments)
      end
      val
    end
  end

  class << self
    # @param [String] class_name name of the class this node will wrap.
    def exposes(*exposes_class_names)
      @exposes_class_names = exposes_class_names
      GraphQL::SCHEMA.add_type(self)
    end

    # The names of the classes wrapped by this node
    def exposes_class_names
      @exposes_class_names || []
    end

    # @param [String] describe
    # Provide a description for this node which will be accessible from {SCHEMA}
    def desc(describe)
      @description = describe
    end

    # The description of this node
    def description
      @description || raise("#{name}.description isn't defined")
    end

    # @param [String] type_name
    # Declares an alternative name to use in {GraphQL::SCHEMA}
    def type(type_name)
      @type_name = type_name.to_s
      GraphQL::SCHEMA.add_type(self)
    end

    # Returns the name of this node used by {GraphQL::SCHEMA}
    def schema_name
      @type_name || default_schema_name
    end

    def default_schema_name
      name.split("::").last.sub(/(Node|Type)$/, '').underscore
    end

    # @param [String] field_name name of the field to be used as the cursor
    # Declares what field will be used as the cursor for this node.
    def cursor(field_name)
      define_method "cursor" do
        field_mapping = self.class.all_fields[field_name.to_s]
        public_send(field_mapping.name).to_s
      end
    end

    # All accessible fields on this node (including those defined in parent classes)
    def all_fields
      superclass.all_fields.merge(own_fields)
    rescue NoMethodError
      own_fields
    end

    # Fields defined by this class, but not its parents
    def own_fields
      @own_fields ||= {}
    end

    # @return [GraphQL::FieldDefiner] definer
    def field
      @field_definer ||= GraphQL::FieldDefiner.new(self)
    end

    # @param [String] field_name
    # Un-define field with name `field_name`
    def remove_field(field_name)
      own_fields.delete(field_name.to_s)
    end

    # Can the node handle a field with this name?
    def respond_to_field?(field_name)
      if all_fields[field_name.to_s].blank?
        false
      elsif method_defined?(field_name)
        true
      elsif exposes_class_names.any? do |exposes_class_name|
          exposes_class = Object.const_get(exposes_class_name)
          exposes_class.method_defined?(field_name) || exposes_class.respond_to?(field_name)
        end
        true
      else
        false
      end
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

    def _calls
      @calls ||= {}
    end
  end

  private

  def get_field(syntax_field)
    field_mapping = self.class.all_fields[syntax_field.identifier]
    if syntax_field.identifier == "cursor"
      cursor
    elsif field_mapping.nil?
      raise GraphQL::FieldNotDefinedError.new(self.class, syntax_field.identifier)
    else
      field_mapping
    end
  end
end