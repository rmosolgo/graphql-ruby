---
layout: doc_stub
search: true
title: GraphQL::InternalRepresentation::Rewrite
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/InternalRepresentation/Rewrite
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/InternalRepresentation/Rewrite
---

Class: GraphQL::InternalRepresentation::Rewrite < Object
While visiting an AST, build a normalized, flattened tree of  No
unions or interfaces are present in this tree, only object types. 
Selections from the AST are attached to the object types they apply
to. 
Inline fragments and fragment spreads are preserved in
{InternalRepresentation::Node#ast_spreads, where they can be used to
check for the presence of directives. This might not be sufficient
for future directives, since the selections' grouping is lost. 
The rewritten query tree serves as the basis for the
`FieldsWillMerge` validation. 
Includes:
GraphQL::Language
Instance methods:
initialize, skip?, validate

