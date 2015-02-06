class GraphQL::Query
  attr_reader :query_string, :root, :namespace
  def initialize(query_string, namespace: nil)
    if !query_string.is_a?(String) || query_string.length == 0
      raise "You must send a query string, not a #{query_string.class.name}"
    end
    @query_string = query_string
    @root = parse(query_string)
    @namespace = namespace || self.class.default_namespace || Object
  end

  def as_json
    root_node = make_call(nil, root.identifier, root.argument)
    raise "Couldn't find root for #{root.identifier}(#{root.argument})" if root.nil?

    root_node.query = self
    root_node.fields = root.fields
    {
      root_node.cursor => root_node.as_json
    }
  end

  def get_node(identifier)
    name = "#{identifier}_node"
    namespace.const_get(name.camelize)
  end

  def get_edge(identifier)
    name = "#{identifier}_edge"
    namespace.const_get(name.camelize)
  end

  def make_call(context, name, *arguments)
    if context.nil?
      context = get_node(name)
      name = "call"
    end
    context.send(name, *arguments)
  end

  class << self
    attr_accessor :default_namespace
  end

  private

  def parse(query_string)
    parsed_hash = GraphQL::PARSER.parse(query_string)
    root_node = GraphQL::TRANSFORM.apply(parsed_hash)
  end
end