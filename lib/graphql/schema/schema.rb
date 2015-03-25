# {GraphQL::SCHEMA} keeps track of defined nodes, fields and calls.
#
# Although you don't interact with it directly, it responds to queries for `schema()` and `__type__` info.
#
# You can validate it at runtime with {#validate}
# @example
#   # validate the schema
#   GraphQL::SCHEMA.validate
#
require "singleton"

class GraphQL::Schema::Schema
  include Singleton
  attr_reader :types, :calls, :class_names
  def initialize
    @types = {}
    @class_names = {}
    @calls = {}
  end

  # Queries the whole schema and returns the result
  def all
    GraphQL::Query.new(GraphQL::Schema::ALL).as_result
  end

  def validate
    validation = GraphQL::Schema::SchemaValidation.new
    validation.validate(self)
  end

  def add_call(call_class)
    remove_call(call_class)
    raise "You can't make #{call_class.name}'s type '#{call_class.schema_name}'" if call_class.schema_name.blank?
    @calls[call_class.schema_name] = call_class
  end

  def get_call(identifier)
    @calls[identifier.to_s] || raise(GraphQL::RootCallNotDefinedError.new(identifier))
  end

  def remove_call(call_class)
    existing_name = @calls.key(call_class)
    if existing_name
      @calls.delete(existing_name)
    end
  end

  def call_names
    @calls.keys
  end

  def add_type(node_class)
    existing_name = @types.key(node_class)
    if existing_name
      @types.delete(existing_name)
    end

    node_class.exposes_class_names.each do |exposes_class_name|
      @class_names[exposes_class_name] = node_class
    end

    @types[node_class.schema_name] = node_class
  end

  def get_type(identifier)
    @types[identifier.to_s] || raise(GraphQL::NodeNotDefinedError.new(identifier))
  end

  def type_names
    @types.keys.sort
  end

  def type_for_object(app_object)
    registered_class_names = @class_names.keys
    if app_object.is_a?(Class)
      app_class = app_object
    else
      app_class = app_object.class
    end
    app_class.ancestors.map(&:name).each do |class_name|
      if registered_class_names.include?(class_name)
        return @class_names[class_name]
      end
    end
    raise "Couldn't find node for class #{app_class} \"#{app_object}\" (ancestors: #{app_class.ancestors.map(&:name)}, defined: #{registered_class_names})"
  end
end