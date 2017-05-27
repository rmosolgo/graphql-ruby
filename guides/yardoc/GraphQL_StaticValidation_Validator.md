---
layout: doc_stub
search: true
title: GraphQL::StaticValidation::Validator
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/StaticValidation/Validator
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/StaticValidation/Validator
---

Class: GraphQL::StaticValidation::Validator < Object
Initialized with a GraphQL::Schema, then it can validate based on
that schema. 
By default, it's used by {GraphQL::Query 
Examples:
# Validate a query
validator = GraphQL::StaticValidation::Validator.new(schema: MySchema)
document = GraphQL.parse(query_string)
errors = validator.validate(document)
Instance methods:
initialize, validate

