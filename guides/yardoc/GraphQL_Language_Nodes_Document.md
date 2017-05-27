---
layout: doc_stub
search: true
title: GraphQL::Language::Nodes::Document
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Language/Nodes/Document
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Language/Nodes/Document
---

Class: GraphQL::Language::Nodes::Document < GraphQL::Language::Nodes...
This is the AST root for normal queries 
Examples:
# Deriving a document by parsing a string
document = GraphQL.parse(query_string)
# Creating a string from a document
document.to_query_string
# { ... }
Instance methods:
initialize_node, slice_definition

