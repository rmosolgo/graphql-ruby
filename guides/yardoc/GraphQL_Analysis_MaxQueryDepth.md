---
layout: doc_stub
search: true
title: GraphQL::Analysis::MaxQueryDepth
url: http://www.rubydoc.info/gems/graphql/GraphQL/Analysis/MaxQueryDepth
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/Analysis/MaxQueryDepth
---

Class: GraphQL::Analysis::MaxQueryDepth < GraphQL::Analysis::QueryDepth
Used under the hood to implement depth validation, see
Schema#max_depth and Query#max_depth 
Examples:
# Assert max depth of 10
# DON'T actually do this, graphql-ruby
# Does this for you based on your `max_depth` setting
MySchema.query_analyzers << GraphQL::Analysis::MaxQueryDepth.new(10)
Instance methods:
initialize

