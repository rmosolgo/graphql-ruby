---
layout: doc_stub
search: true
title: GraphQL::Language::Visitor
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Language/Visitor
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Language/Visitor
---

Class: GraphQL::Language::Visitor < Object
Depth-first traversal through the tree, calling hooks at each stop. 
Examples:
# Create a visitor, add hooks, then search a document
total_field_count = 0
visitor = GraphQL::Language::Visitor.new(document)
# Whenever you find a field, increment the field count:
visitor[GraphQL::Language::Nodes::Field] << ->(node) { total_field_count += 1 }
# When we finish, print the field count:
visitor[GraphQL::Language::Nodes::Document].leave << ->(node) { p total_field_count }
visitor.visit
# => 6
Class methods:
apply_hooks
Instance methods:
[], begin_visit, end_visit, initialize, visit, visit_node

