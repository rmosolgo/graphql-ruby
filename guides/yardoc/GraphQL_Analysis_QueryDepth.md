---
layout: doc_stub
search: true
title: GraphQL::Analysis::QueryDepth
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Analysis/QueryDepth
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Analysis/QueryDepth
---

Class: GraphQL::Analysis::QueryDepth < Object
A query reducer for measuring the depth of a given query. 
Examples:
# Logging the depth of a query
Schema.query_analyzers << GraphQL::Analysis::QueryDepth.new { |query, depth|  puts "GraphQL query depth: #{depth}" }
Schema.execute(query_str)
# GraphQL query depth: 8
Direct Known Subclasses:
MaxQueryDepth
Instance methods:
call, final_value, initial_value, initialize

