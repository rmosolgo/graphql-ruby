# {Connection}s wrap collections of objects.
#
# Out of the box, the only field it has is `edges`, which provides access to the members of the collection.
#
# You can define a custom {Connection} to use. This allows you to define fields and calls at the collection level (rather than the item level)
#
# You can access the collection as `target` ({Node#target}).
#
# @example
#   class UpvotesConnection < GraphQL::Collection
#     type :upvotes # adds it to the schema
#     call :first, -> (prev_items, first) { prev_items.first(first.to_i) }
#     call :after, -> (prev_items, after) { prev_items.select {|i| i.id > after.to_i } }
#
#     field.number(:count) # delegates to the underlying collection
#     field.boolean(:any)
#
#     def any
#       target.any?
#     end
#   end
#
#   # Then, this connection will be used for connections whose names match:
#   class PostNode < GraphQL::Node
#     field.upvotes(:upvotes)
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
  field.object(:edges)

  def edge_fields
    @edge_fields ||= syntax_fields.find { |f| f.identifier == "edges" }.fields
  end

  def edges
    raise "#{self.class} expected a connection, but got `nil`" if target.nil?
    target.map do |item|
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
  end
end