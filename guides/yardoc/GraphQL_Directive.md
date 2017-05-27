---
layout: doc_stub
search: true
title: GraphQL::Directive
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Directive
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Directive
---

Class: GraphQL::Directive < Object
Directives are server-defined hooks for modifying execution. 
Two directives are included out-of-the-box: - `@skip(if: ...)` Skips
the tagged field if the value of `if` is true - `@include(if: ...)`
Includes the tagged field _only_ if `if` is true 
Includes:
GraphQL::Define::InstanceDefinable
Instance methods:
default_arguments, default_directive?, initialize, on_field?,
on_fragment?, on_operation?, to_s

