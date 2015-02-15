class GraphQL::Connection < GraphQL::Node
  field :edges

  attr_reader :calls, :fields, :query, :node_class

  def initialize(items, node_class:, query:, fields: [])
    @target = items
    @fields = fields
    @query = query
    @node_class = node_class
  end

  def items
    @target
  end

  def edge_fields
    @edge_fields = fields.find { |f| f.identifier == "edges" }.fields
  end

  def edges
    items.map do |item|
      node = node_class.new(item, fields: edge_fields, query: query)
      node.as_result
    end
  end
end