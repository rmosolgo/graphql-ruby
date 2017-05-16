---
layout: doc_stub
search: true
title: GraphQL::Compatibility::ExecutionSpecification
url: http://www.rubydoc.info/gems/graphql/GraphQL/Compatibility/ExecutionSpecification
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/Compatibility/ExecutionSpecification
---

Module: GraphQL::Compatibility::ExecutionSpecification
Test an execution strategy. This spec is not meant as a development
aid. Rather, when the strategy _works_, run it here to see if it has
any differences from the built-in strategy. 
- Custom scalar input / output - Null propagation - Query-level
masking - Directive support - Typecasting - Error handling (raise /
return GraphQL::ExecutionError) - Provides Irep & AST node to
resolve fn - Skipping fields 
Some things are explicitly _not_ tested here, because they're
handled by other parts of the system: 
- Schema definition (including types and fields) - Parsing & parse
errors - AST -> IRep transformation (eg, fragment merging) - Query
validation and analysis - Relay features 
Defined Under Namespace:
CounterSchema, SpecificationSchema (modules)
Class methods:
build_suite

