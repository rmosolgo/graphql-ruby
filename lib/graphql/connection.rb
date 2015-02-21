class GraphQL::Connection < GraphQL::Node
  exposes "Array"
  field.any(:edges)

  attr_reader :calls, :syntax_fields, :query

  def initialize(items, query:, fields: [])
    @target = items
    @syntax_fields = fields
    @query = query
  end

  def items
    @target
  end

  def edge_fields
    @edge_fields ||= syntax_fields.find { |f| f.identifier == "edges" }.fields
  end

  def edges
    raise "#{self.class} expected a connection, but got `nil`" if items.nil?
    items.map do |item|
      node_class = GraphQL::SCHEMA.type_for_object(item)
      node = node_class.new(item, fields: edge_fields, query: query)
      res = node.as_result
      res
    end
  end

  class << self
    def default_schema_name
      name.split("::").last.sub(/Connection$/, '').underscore
    end

    attr_accessor :default_connection
    def default_connection!
      GraphQL::Connection.default_connection = self
    end

  end

  self.default_connection!
end