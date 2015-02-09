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

  def get_edge(identifier)
    name = "#{identifier}_edge"
    namespace.const_get(name.camelize)
  end

  class << self
    attr_accessor :default_namespace
  end

  private

  def execute!
    if root.identifier == "type"
      root_node = GraphQL::Introspection::TypeNode.call(*root.arguments)
    else
      root_node = fetch_root_node
    end

    root_node.query = self
    root_node.fields = root.fields
    {
      root_node.cursor => root_node.as_json
    }
  end

  def fetch_root_node
    root_class = get_node(root.identifier)
    root_node = root_class.send(:call, *root.arguments)

    if !root_node.is_a?(root_class)
      raise "#{root_call.name}.call must return an instance of #{root_class.name}, not an instance of #{root_node.class.name}"
    end

    root_node
  end


  def parse(query_string)
    parsed_hash = GraphQL::PARSER.parse(query_string)
    root_node = GraphQL::TRANSFORM.apply(parsed_hash)
  rescue Parslet::ParseFailed => error
    line, col = error.cause.source.line_and_column
    raise GraphQL::SyntaxError.new(line, col, query_string)
  end
end