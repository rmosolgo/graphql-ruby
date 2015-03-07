# {Connection}s wrap collections of objects.
#
# Out of the box, the only field it has is `edges`, which provides access to the members of the collection.
#
# You can define a custom {Connection} to use. This allows you to define fields at the collection level (rather than the item level)
#
# Custom fields can access the collection as {Field#items}.
#
# @example
#   class UpvotesConnection < GraphQL::Collection
#     field.number(:count)
#     field.boolean(:any)
#
#     def count
#       items.count
#     end
#
#     def any
#       items.any?
#     end
#   end
#
#   # Then, this connection will be used for connections whose names match:
#   class PostNode < GraphQL::Node
#     field.connection(:upvotes)
#     # ^^ uses `UpvotesConnection` based on naming convention
#   end
#
#   # And you can use the fields in a query:
#   <<QUERY
#   find_post(10) {
#     title,
#     upvotes {
#       count,
#       any,
#       edges {
#         node { created_at }
#       }
#     }
#   }
#   QUERY
class GraphQL::Connection < GraphQL::Node
  exposes "Array"
  field.any(:edges)

  attr_reader :calls, :syntax_fields, :query

  def initialize(items, query:, fields: [])
    @target = items
    @syntax_fields = fields
    @query = query
  end

  # Returns the members of the collection, after any calls on the corresponding {Field} have been applied
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
    # Call this to make a the class the default connection
    # when one isn't found by name.
    def default_connection!
      GraphQL::Connection.default_connection = self
    end

  end

  self.default_connection!
end