---
layout: doc_stub
search: true
title: GraphQL::ExecutionError
url: http://www.rubydoc.info/gems/graphql/GraphQL/ExecutionError
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/ExecutionError
---

Class: GraphQL::ExecutionError < GraphQL::Error
If a field's resolve function returns a ExecutionError, the error
will be inserted into the response's `"errors"` key and the field
will resolve to `nil`. 
Direct Known Subclasses:
AnalysisError, Query::OperationNameMissingError,
Query::VariableValidationError, Schema::TimeoutMiddleware::TimeoutError
Instance methods:
initialize, to_h

