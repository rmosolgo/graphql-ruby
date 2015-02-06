class GraphQL::CollectionEdge
  attr_accessor :fields, :node_class, :calls, :fields, :query

  def initialize(items:, node_class:)
    @items = items
    @node_class = node_class
  end

  def as_json
    json = {}
    fields.each do |field|
      name = field.identifier
      if name == "edges"
        json["edges"] = edges(fields: field.fields)
      else
        json[name] = safe_send(name)
      end
    end
    json
  end

  def count
    @items.count
  end

  def apply_calls(unfiltered_items, call_hash)
    # override this to apply calls to your items
    unfiltered_items
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
          json[name] = node.as_json
        else
          json[name] = node.safe_send(name)
        end
      end
      json
    end
  end

  def safe_send(identifier)
    if respond_to?(identifier)
      public_send(identifier)
    else
      raise GraphQL::FieldNotDefinedError, "#{self.class.name}##{identifier} was requested, but it isn't defined."
    end
  end

  private

  def items
    @items
  end
end