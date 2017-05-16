---
layout: doc_stub
search: true
title: GraphQL::Relay::BaseConnection
url: http://www.rubydoc.info/gems/graphql/GraphQL/Relay/BaseConnection
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/Relay/BaseConnection
---

Class: GraphQL::Relay::BaseConnection < Object
Subclasses must implement:
- #cursor_from_node, which returns an opaque cursor for the given
item
- #sliced_nodes, which slices by `before` & `after`
- #paged_nodes, which applies `first` & `last` limits
In a subclass, you have access to
- #nodes, the collection which the connection will wrap
- #first, #after, #last, #before (arguments passed to the field)
- #max_page_size (the specified maximum page size that can be
returned from a connection)
Direct Known Subclasses:
ArrayConnection, RelationConnection
Class methods:
connection_for_nodes, register_connection_implementation
Instance methods:
after, before, cursor_from_node, decode, edge_nodes, encode,
end_cursor, first, get_limited_arg, has_next_page,
has_previous_page, initialize, last, page_info, paged_nodes,
sliced_nodes, start_cursor

