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
  # The object wrapped by this `Node`
  attr_reader :target
  # Fields parsed from the query string
  attr_reader :syntax_fields
  # The query to which this `Node` belongs. Used for accessing its {Query#context}.
  attr_reader :query

  def initialize(target=nil, fields:, query:)
    @target = target
    @query = query
    @syntax_fields = fields
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

  # The object passed to {Query#initialize} as `context`.
  def context
    query.context
  end


  class << self
    # Registers this node in {GraphQL::SCHEMA}
    def inherited(child_class)
      # use name to prevent autoloading Connection
      if child_class.ancestors.map(&:name).include?("GraphQL::Connection")
        GraphQL::SCHEMA.add_connection(child_class)
      end
    end

    # @param [String] class_name name of the class this node will wrap.
    def exposes(ruby_class_name)
      @ruby_class_name = ruby_class_name
      GraphQL::SCHEMA.add_type(self)
    end

    # The name of the class wrapped by this node
    def ruby_class_name
      @ruby_class_name
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
      name.split("::").last.sub(/Node$/, '').underscore
    end

    # @param [String] field_name name of the field to be used as the cursor
    # Declares what field will be used as the cursor for this node.
    def cursor(field_name)
      define_method "cursor" do
        field_class = self.class.all_fields[field_name.to_s]
        field = field_class.new(query: query, owner: self, calls: [])
        cursor = GraphQL::Types::CursorField.new(field.as_result)
        cursor.as_result
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
  end

  private

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
end