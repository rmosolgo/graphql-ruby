---
layout: doc_stub
search: true
title: GraphQL::BaseType
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/BaseType
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/BaseType
---

Class: GraphQL::BaseType < Object
The parent for all type classes. 
Direct Known Subclasses:
EnumType, InputObjectType, InterfaceType, ListType, NonNullType,
ObjectType, ScalarType, UnionType
Includes:
GraphQL::Define::InstanceDefinable, GraphQL::Define::NonNullWithBang
Class methods:
resolve_related_type
Instance methods:
==, coerce_input, coerce_isolated_input, coerce_isolated_result,
coerce_result, connection_type, default_relay?, default_scalar?,
define_connection, define_edge, edge_type, get_field, initialize,
initialize_copy, introspection?, resolve_type, to_definition,
to_list_type, to_non_null_type, to_s, unwrap, valid_input?,
valid_isolated_input?, validate_input, validate_isolated_input,
warn_deprecated_coerce

