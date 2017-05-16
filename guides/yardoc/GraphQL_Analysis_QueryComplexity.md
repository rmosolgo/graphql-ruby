---
layout: doc_stub
search: true
title: GraphQL::Analysis::QueryComplexity
url: http://www.rubydoc.info/gems/graphql/GraphQL/Analysis/QueryComplexity
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/Analysis/QueryComplexity
---

Class: GraphQL::Analysis::QueryComplexity < Object
Calculate the complexity of a query, using Field#complexity values. 
Examples:
# Log the complexity of incoming queries
MySchema.query_analyzers << GraphQL::Analysis::QueryComplexity.new do |query, complexity|
Rails.logger.info("Complexity: #{complexity}")
end
Direct Known Subclasses:
MaxQueryComplexity
Instance methods:
call, final_value, get_complexity, initial_value, initialize

