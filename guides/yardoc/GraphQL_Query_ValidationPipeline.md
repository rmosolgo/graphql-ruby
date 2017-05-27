---
layout: doc_stub
search: true
title: GraphQL::Query::ValidationPipeline
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Query/ValidationPipeline
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Query/ValidationPipeline
---

Class: GraphQL::Query::ValidationPipeline < Object
This class is part of a private API.
Contain the validation pipeline and expose the results. 
0. Checks in Query#initialize:
- Rescue a ParseError, halt if there is one
- Check for selected operation, halt if not found
1. Validate the AST, halt if errors 2. Validate the variables, halt
if errors 3. Run query analyzers, halt if errors 
#valid? is false if any of the above checks halted the pipeline. 
Instance methods:
analysis_errors, analyzers, build_analyzers, ensure_has_validated,
initialize, internal_representation, valid?, validation_errors

