---
layout: doc_stub
search: true
title: GraphQL::Analysis::FieldUsage
url: http://www.rubydoc.info/gems/graphql/GraphQL/Analysis/FieldUsage
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/Analysis/FieldUsage
---

Class: GraphQL::Analysis::FieldUsage < Object
A query reducer for tracking both field usage and deprecated field
usage. 
Examples:
# Logging field usage and deprecated field usage
Schema.query_analyzers << GraphQL::Analysis::FieldUsage.new { |query, used_fields, used_deprecated_fields|
puts "Used GraphQL fields: #{used_fields.join(', ')}"
puts "Used deprecated GraphQL fields: #{used_deprecated_fields.join(', ')}"
}
Schema.execute(query_str)
# Used GraphQL fields: Cheese.id, Cheese.fatContent, Query.cheese
# Used deprecated GraphQL fields: Cheese.fatContent
Instance methods:
call, final_value, initial_value, initialize

