---
layout: doc_stub
search: true
title: GraphQL::StaticValidation::VariablesAreUsedAndDefined
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/StaticValidation/VariablesAreUsedAndDefined
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/StaticValidation/VariablesAreUsedAndDefined
---

Class: GraphQL::StaticValidation::VariablesAreUsedAndDefined < Object
The problem is
- Variable usage must be determined at the OperationDefinition
level
- You can't tell how fragments use variables until you visit
FragmentDefinitions (which may be at the end of the document)
So, this validator includes some crazy logic to follow fragment
spreads recursively, while avoiding infinite loops.
`graphql-js` solves this problem by:
- re-visiting the AST for each validator
- allowing validators to say `followSpreads: true`
Includes:
GraphQL::StaticValidation::Message::MessageHelper
Instance methods:
create_errors, follow_spreads, validate, variable_hash

