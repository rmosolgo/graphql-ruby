class GraphQL::Edge < GraphQL::Field
  include GraphQL::Fieldable

  attr_reader :items, :calls, :fields, :query, :node_class

  def initialize(items:, node_class:, query:, calls: [], fields: [])
    @items = items
    @fields = fields
    @calls = calls
    @query = query
    @node_class = node_class
  end

  def value
    as_json
  end

  def as_json
    json = {}
    fields.each do |field|
      name = field.identifier
      if name == "edges"
        json["edges"] = edges(fields: field.fields)
      else
        field = get_field(field)
        json[name] = field.value
      end
    end
    json
  end

  def filtered_items
    @filtered_items ||= apply_calls(items, calls)
  end

  def edges(fields:)
    filtered_items.map do |item|
      node = node_class.new(item)
      json = {}
      fields.each do |field|
        name = field.identifier
        if name == "node" # it's magic
          node.fields = field.fields
          node.query = query
          json[name] = node.as_json
        else
          json[name] = node.get_field(field)
        end
      end
      json
    end
  end

  def context
    query.context
  end

  def method_missing(method_name, *args, &block)
    if items.respond_to?(method_name)
      items.public_send(method_name, *args, &block)
    else
      super
    end
  end
end