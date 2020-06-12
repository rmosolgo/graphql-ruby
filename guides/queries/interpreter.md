---
title: Interpreter
layout: guide
doc_stub: false
search: true
section: Queries
desc: A New Runtime for GraphQL-Ruby
index: 11
---

GraphQL-Ruby 1.9.0 includes a new runtime module which you may use for your schema. Eventually, it will become the default.

It's called `GraphQL::Execution::Interpreter` and you can hook it up with `use ...` in your schema class:

```ruby
class MySchema < GraphQL::Schema
  use GraphQL::Execution::Interpreter
  # Also required in GraphQL-Ruby 1.10+:
  use GraphQL::Analysis::AST
end
```

Read on to learn more!

## Rationale

The new runtime was added to address a few specific concerns:

- __Validation Performance__: The previous runtime depended on a preparation step (`GraphQL::InternalRepresentation::Rewrite`) which could be very slow in some cases. In many cases, the overhead of that step provided no value.
- __Runtime Performance__: For very large results, the previous runtime was slow because it allocated a new `ctx` object for every field, even very simple fields that didn't need any special tracking.
- __Extensibility__: Although the GraphQL specification supports custom directives, GraphQL-Ruby didn't have a good way to build them.

## Installation

You can opt in to the interpreter in your schema class:

```ruby
class MySchema < GraphQL::Schema
  use GraphQL::Execution::Interpreter
  # Also required in GraphQL-Ruby 1.10+:
  use GraphQL::Analysis::AST
end
```

Some Relay configurations must be updated too. For example:

```diff
- field :node, field: GraphQL::Relay::Node.field
+ add_field(GraphQL::Types::Relay::NodeField)
```

(Alternatively, consider implementing `Query.node` in your own app, using `NodeField` as inspiration.)

## Compatibility

The new runtime works with class-based schemas only. Several features are no longer supported:

- Proc-dependent field features:

  - Field Instrumentation
  - Middleware
  - Resolve procs
  - `GraphQL::Function`

  All these depend on the memory- and time-hungry per-field `ctx` object. To improve performance, only method-based resolves are supported. If need something from `ctx`, you can get it with the `extras: [...]` configuration option. To wrap resolve behaviors, try {% internal_link "Field Extensions", "/type_definitions/field_extensions" %}, {% internal_link "Tracing", "/queries/tracing" %}, or {% internal_link "GraphQL::Schema::Resolver", "/fields/resolvers" %}.

- Query analyzers and `irep_node`s

  These depend on the now-removed `Rewrite` step, which wasted a lot of time making often-unneeded preparation. Most of the attributes you might need from an `irep_node` are available with `extras: [...]`. Query analyzers can be refactored to be static checks (custom validation rules) or dynamic checks, made at runtime. The built-in analyzers have been refactored to run as validators.

  For a replacement, check out:

  - {{ "GraphQL::Execution::Lookahead" | api_doc }} for field-level info about child selections
  - {{ "GraphQL::Analysis::AST" | api_doc }} for query analysis which is compatible with the new interpreter

- `rescue_from`

  This was built on middleware, which is not supported anymore. For a replacement, see {% internal_link "Error Handling", "/errors/error_handling" %}.

- `.graphql_definition` and `def to_graphql`

  The interpreter uses class-based schema definitions only, and never converts them to legacy GraphQL definition objects. Any custom definitions to GraphQL objects should be re-implemented on custom base classes.

- `GraphQL::Schema::Field#resolve_field`

  If you customized your base field's resolution method, it needs an update. The interpreter calls a different method: `#resolve(obj, args, ctx)`. There are two differences with the new method:

  - `args` is plain ol' Ruby Hash, with symbol keys, instead of a `GraphQL::Query::Arguments`
  - `ctx` is a `GraphQL::Query::Context` instead of a `GraphQL::Query::Context::FieldResolutionContext`

  But besides that, it's largely the same.

Maybe this section should have been called _incompatibility_ 🤔.

## Extending the Runtime

See {% internal_link "Directives", "/type_definitions/directives" %}.

## Analyzers

GraphQL-Ruby has "analyzers" that run _before_ execution and may reject a query. With the interpreter, you can use {% internal_link "AST Analyzers", "/queries/ast_analysis" %} to get better performance.

To make the migration, convert your previous analyzers to extend {{ "GraphQL::Analysis::AST::Analyzer" | api_doc }} as described in the guide, then add to your schema:

```ruby
use GraphQL::Analysis::AST
```

When you use _both_ `Interpreter` and `Analysis::AST`, GraphQL-Ruby will skip the slow process of building `irep_nodes`.

All analyzers must be migrated at once; running _some_ legacy analyzers and _some_ AST analyzers is not supported.


In GraphQL-Ruby 1.9, you can migrate to `Interpreter` before migrating to `Analysis::AST`. In that case, the `irep_node` tree will still be constructed and used for analysis, even though it will not be used for execution.

In GraphQL-Ruby 1.10+, `Interpreter` _requires_ `Analysis::AST` and will not work without it. (Soon, these will be the default runtime modules.)

## Implementation Notes

Instead of a tree of `irep_nodes`, the interpreter consumes the AST directly. This removes a complicated concept from GraphQL-Ruby (`irep_node`s) and simplifies the query lifecycle. The main difference relates to how fragment spreads are resolved. In the previous runtime, the possible combinations of fields for a given object were calculated ahead of time, then some of those combinations were used during runtime, but many of them may not have been. In the new runtime, no precalculation is made; instead each object is checked against each fragment at runtime.

Instead of creating a `GraphQL::Query::Context::FieldResolutionContext` for _every_ field in the response, the interpreter uses long-lived, mutable objects for execution bookkeeping. This is more complicated to manage, since the changes to those objects can be hard to predict, but it's worth it for the performance gain. When needed, those bookkeeping objects can be "forked", so that two parts of an operation can be resolved independently.

Instead of calling `.to_graphql` internally to convert class-based definitions to `.define`-based definitions, the interpreter operates on class-based definitions directly. This simplifies the workflow for creating custom configurations and using them at runtime.
