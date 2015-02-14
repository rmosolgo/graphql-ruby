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

  def get_node(identifier)
    identifier = identifier.camelize
    if GraphQL::TYPE_ALIASES.has_key?(identifier)
      return GraphQL::TYPE_ALIASES[identifier]
    end
    name = "#{identifier}Node"
    namespace.const_get(name)
  rescue NameError => e
    if namespace != Object
      name  = "#{namespace}::#{name}"
    end
    raise GraphQL::NodeNotDefinedError.new(name)
  end

  def const_get(identifier)
    if namespace.const_defined?(identifier)
      namespace.const_get(identifier)
    else
      nil
    end
  end

  class << self
    attr_accessor :default_namespace
  end

  private

  def execute!
    root_nodes = fetch_root_node

    result = {}

    root_nodes.each do |n|
      result[n.cursor] = n.as_json
    end

    result
  end

  def fetch_root_node
    if root.identifier == "type"
      root_class = GraphQL::Introspection::TypeNode
    else
      root_class = get_node(root.identifier)
    end

    # if only one object, make an array of it
    root_nodes = root_class.send(:call, *root.arguments, query: self, fields: root.fields)
    if !root_nodes.is_a?(Array)
      root_nodes = [root_nodes]
    end

    if !root_nodes[0].is_a?(root_class)
      raise "#{root_class.name}.call must return an instance of #{root_class.name}, not an instance of #{root_nodes[0].class.name}"
    end

    root_nodes
  end


  def parse(query_string)
    parsed_hash = GraphQL::PARSER.parse(query_string)
    root_node = GraphQL::TRANSFORM.apply(parsed_hash)
  rescue Parslet::ParseFailed => error
    line, col = error.cause.source.line_and_column
    raise GraphQL::SyntaxError.new(line, col, query_string)
  end
end