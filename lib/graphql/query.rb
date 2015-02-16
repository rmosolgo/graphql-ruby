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

  def as_result
    @as_result ||= execute!
  end

  def as_json; as_result; end

  def const_get(identifier)
    if namespace.const_defined?(identifier)
      namespace.const_get(identifier)
    else
      nil
    end
  end

  def get_variable(identifier)
    syntax_var = @root.variables.find { |v| v.identifier == identifier }
    if syntax_var.blank?
      raise "No variable found for #{identifier}, defined variables are #{@root.variables.map(&:identifier)}"
    end
    syntax_var
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
    result_object = root_call.as_result
    return_declarations = root_call_class.return_declarations
    result = {}

    if result_object.is_a?(Hash)
      result_object.each do |name, value|
        node_type = root_call_class.return_declarations[name]
        node_class = GraphQL::SCHEMA.get_node(node_type)
        field_for_node = root_syntax_node.fields.find {|f| f.identifier == name.to_s }
        if field_for_node.present?
          fields_for_node = field_for_node.fields
          node_value = node_class.new(value,query: self, fields: fields_for_node)
          result[name.to_s] = node_value.as_result
        end
      end
    elsif result_object.is_a?(Array)
      node_type = root_call_class.return_declarations.values.first
      node_class = GraphQL::SCHEMA.get_node(node_type)
      fields_for_node = root_syntax_node.fields
      result_object.each do |item|
        node_value = node_class.new(item, query: self, fields: fields_for_node)
        result[node_value.cursor] = node_value.as_result
      end
    else
      node_type = root_call_class.return_declarations.values.first
      node_class = GraphQL::SCHEMA.get_node(node_type)
      fields_for_node = root_syntax_node.fields
      node_value = node_class.new(result_object, query: self, fields: fields_for_node)
      result[node_value.cursor] = node_value.as_result
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