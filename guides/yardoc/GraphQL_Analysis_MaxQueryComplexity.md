---
layout: doc_stub
search: true
title: GraphQL::Analysis::MaxQueryComplexity
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Analysis/MaxQueryComplexity
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Analysis/MaxQueryComplexity
---

Class: GraphQL::Analysis::MaxQueryComplexity < GraphQL::Analysis::Qu...
Used under the hood to implement complexity validation, see
Schema#max_complexity and Query#max_complexity 
Examples:
# Assert max complexity of 10
# DON'T actually do this, graphql-ruby
# Does this for you based on your `max_complexity` setting
MySchema.query_analyzers << GraphQL::Analysis::MaxQueryComplexity.new(10)
Instance methods:
initialize

