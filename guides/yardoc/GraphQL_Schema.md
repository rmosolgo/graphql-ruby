---
layout: doc_stub
search: true
title: GraphQL::Schema
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Schema
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Schema
---

Class: GraphQL::Schema < Object
A GraphQL schema which may be queried with GraphQL::Query. 
The Schema contains: 
- types for exposing your application
- query analyzers for assessing incoming queries (including max
depth & max complexity restrictions)
- execution strategies for running incoming queries
- middleware for interacting with execution
Schemas start with root types, Schema#query, Schema#mutation and
Schema#subscription. The schema will traverse the tree of fields &
types, using those as starting points. Any undiscoverable types may
be provided with the `types` configuration. 
Schemas can restrict large incoming queries with `max_depth` and
`max_complexity` configurations. (These configurations can be
overridden by specific calls to Schema#execute) 
Schemas can specify how queries should be executed against them.
`query_execution_strategy`, `mutation_execution_strategy` and
`subscription_execution_strategy` each apply to corresponding root
types. 
A schema accepts a `Relay::GlobalNodeIdentification` instance for
use with Relay IDs. 
Examples:
# defining a schema
MySchema = GraphQL::Schema.define do
query QueryType
middleware PermissionMiddleware
rescue_from(ActiveRecord::RecordNotFound) { "Not found" }
# If types are only connected by way of interfaces, they must be added here
orphan_types ImageType, AudioType
end
Includes:
GraphQL::Define::InstanceDefinable
Class methods:
from_definition, from_introspection
Instance methods:
as_json, build_instrumented_field_map, build_types_map, define,
execute, execution_strategy_for_operation, get_field, get_fields,
id_from_object, id_from_object=, initialize, initialize_copy,
instrument, lazy?, lazy_method_name, multiplex, object_from_id,
object_from_id=, parse_error, parse_error=, possible_types,
remove_handler, rescue_from, rescue_middleware, rescues?,
resolve_type, resolve_type=, root_type_for_operation, to_definition,
to_json, type_error, type_error=, type_from_ast, types, validate

