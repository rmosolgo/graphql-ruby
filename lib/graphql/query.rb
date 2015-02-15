class GraphQL::Query
  attr_reader :query_string, :root, :namespace, :context
  def initialize(query_string, namespace: nil, context: nil)
    if !query_string.is_a?(String) || query_string.length == 0
      raise "You must send a query string, not a #{query_string.class.name}"
    end
    @query_string = query_string
    @root = parse(query_string)
    @namespace = namespace || self.class.default_namespace || Object
    @context = context
  end

  def as_json
    @as_json ||= execute!
  end

  def const_get(identifier)
    if namespace.const_defined?(identifier)
      namespace.const_get(identifier)
    else
      nil
    end
  end

  def get_variable(identifier)
    syntax_var = @root.variables.find { |v| v.identifier == identifier }
    # to do: memoize
    JSON.parse(syntax_var.json_string)
  end

  class << self
    attr_accessor :default_namespace
  end

  private

  def execute!
    root_syntax_node = root.nodes[0]
    root_call_identifier = root_syntax_node.identifier
    root_call_class = GraphQL::SCHEMA.get_call(root_call_identifier)
    root_call = root_call_class.new(query: self, syntax_arguments: root_syntax_node.arguments)
    result_hash = root_call.as_result
    result = {}

    type = result_hash.delete("__type__")

    result_hash.each do |cursor, value|
      if value.is_a?(GraphQL::Node)
        result[cursor] = value.as_result
        next
      elsif type
        node_class = type
        fields_for_node = root_syntax_node.fields
      else
        node_class = GraphQL::SCHEMA.get_node(cursor)
        field_for_node = root_syntax_node.fields.find {|f| f.identifier == cursor }
        fields_for_node = field_for_node.fields
      end
      node_value = node_class.new(value,query: self, fields: fields_for_node )
      result[cursor] = node_value.as_result
    end

    result
  end

  def parse(query_string)
    parsed_hash = GraphQL::PARSER.parse(query_string)
    root_node = GraphQL::TRANSFORM.apply(parsed_hash)
  rescue Parslet::ParseFailed => error
    line, col = error.cause.source.line_and_column
    raise GraphQL::SyntaxError.new(line, col, query_string)
  end
end