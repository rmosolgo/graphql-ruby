# Changelog

### Breaking changes & deprecations

### New features

### Bug fixes

## 0.12.0 (20 Mar 2016)

### Breaking changes & deprecations

- `GraphQL::DefinitionConfig` was replaced by `GraphQL::Define` #116
- Many scalar types are more picky about which inputs they allow (#115). To get the previous behavior, add this to your program:

  ```ruby
  # Previous coerce behavior for scalars:
  GraphQL::BOOLEAN_TYPE.coerce = -> (value) { !!value }
  GraphQL::ID_TYPE.coerce = -> (value) { value.to_s }
  GraphQL::STRING_TYPE.coerce = ->  (value) { value.to_s }
  # INT_TYPE and FLOAT_TYPE were unchanged
  ```

- `GraphQL::Field`s can't be renamed because `#resolve` may depend on that name. (This was only a problem if you pass the _same_ `GraphQL::Field` instance to `field ... field:` definitions.)
- `GraphQL::Query::DEFAULT_RESOLVE` was removed. `GraphQL::Field#resolve` handles that behavior.

### New features

- Can override `max_depth:` from `Schema#execute`
- Base `GraphQL::Error` for all graphql-related errors

### Bug fixes

- Include `""` for String default values (so it's encoded as a GraphQL string literal)

## 0.11.1 (6 Mar 2016)

### New features

- Schema `max_depth:` option #110
- Improved validation errors for input objects #104
- Interfaces provide field implementations to object types #108

## 0.11.0 (28 Feb 2016)

### Breaking changes & deprecations

- `GraphQL::Query::BaseExecution` was removed, you should probably extend `SerialExecution` instead #96
- `GraphQL::Language::Nodes` members no longer raise if they don't get inputs during `initialize` #92
- `GraphQL.parse` no longer accepts `as:` for parsing partial queries.  #92

### New features

- `Field#property` & `Field#property=` can be used to access & modify the method that will be sent to the underlying object when resolving a field #88
- When defining a field, you can pass a string for as `type`. It will be looked up in the global namespace.
- `Query::Arguments#to_h` unwraps `Arguments` objects recursively
- If you raise `GraphQL::ExecutionError` during field resolution, it will be rescued and the message will be added to the response's `errors` key. #93
- Raise an error when non-null fields are `nil` #94

### Bug fixes

- Accept Rails params as input objects
- Don't get a runtime error when input contains unknown key #100

## 0.10.9 (15 Jan 2016)

### Bug fixes

- Handle re-assignment of `ObjectType#interfaces` #84
- Fix merging queries on interface-typed fields #85

## 0.10.8 (14 Jan 2016)

### Bug fixes

- Fix transform of nested lists #79
- Fix parse & transform of escaped characters #83

## 0.10.7 (22 Dec 2015)

### New features

- Support Rubinius

### Bug fixes

- Coerce values into one-item lists for ListTypes

## 0.10.6 (20 Dec 2015)

### Bug fixes

- Remove leftover `puts`es

## 0.10.5 (19 Dec 2015)

### Bug fixes

- Accept enum value description in definition #71
- Correctly parse empty input objects #75
- Correctly parse arguments preceded by newline
- Find undefined input object keys during static validation

## 0.10.4 (24 Nov 2015)

### New features

- Add `Arguments#to_h` #66

### Bug fixes

- Accept argument description in definition
- Correctly parse empty lists

## 0.10.3 (11 Nov 2015)

### New features

- Support root-level `subscription` type

### Bug fixes

- Require Set for Schema::Printer

## 0.10.2 (10 Nov 2015)

### Bug fixes

- Handle blank strings in queries
- Raise if a field is configured without a proper type #61

## 0.10.1 (22 Oct 2015)

### Bug fixes

- Properly merge fields on fragments within fragments
- Properly delegate enumerable-ish methods on `Arguments` #56
- Fix & refactor literal coersion & validation #53

## 0.10.0 (17 Oct 2015)

### New features

- Scalars can have distinct `coerce_input` and `coerce_result` methods #48
- Operations don't require a name #54

### Bug fixes

- Big refactors and fixes to variables and arguments:
  - Correctly apply argument default values
  - Correctly apply variable default values
  - Raise at execution-time if non-null variables are missing
  - Incoming values are coerced to their proper types before execution

## 0.9.5 (1 Oct 2015)

### New features

- Add `Schema#middleware` to wrap field access
- Add `RescueMiddleware` to handle errors during field execution
- Add `Schema::Printer` for printing the schema definition #45

### Bug fixes

## 0.9.4 (22 Sept 2015)

### New features

- Fields can return `GraphQL::ExecutionError`s to add errors to the response

### Bug fixes

- Fix resolution of union types in some queries #41

## 0.9.3 (15 Sept 2015)

### New features

- Add `Schema#execute` shorthand for running queries
- Merge identical fields in fragments so they're only resolved once #34
- An error during parsing raises `GraphQL::ParseError`  #33

### Bug fixes

- Find nested input types in `TypeReducer` #35
- Find variable usages inside fragments during static validation

## 0.9.2, 0.9.1 (10 Sept 2015)

### Bug fixes

- remove Celluloid dependency

## 0.9.0 (10 Sept 2015)

### Breaking changes & deprecations

- remove `GraphQL::Query::ParallelExecution` (use [`graphql-parallel`](https://github.com/rmosolgo/graphql-parallel))

## 0.8.1 (10 Sept 2015)

### Breaking changes & deprecations

- `GraphQL::Query::ParallelExecution` has been extracted to [`graphql-parallel`](https://github.com/rmosolgo/graphql-parallel)


## 0.8.0 (4 Sept 2015)

### New features

- Async field resolution with `context.async { ... }`
- Access AST node during resolve with `context.ast_node`

### Bug fixes

- Fix for validating arguments returning up too soon
- Raise if you try to define 2 types with the same name
- Raise if you try to get a type by name but it doesn't exist

## 0.7.1 (27 Aug 2015)

### Bug fixes

- Merge nested results from different fragments instead of using the latest one only

## 0.7.0 (26 Aug 2015)

### Breaking changes & deprecations

- Query keyword argument `params:` was removed, use `variables:` instead.

### Bug fixes

- `@skip` has precedence over `@include`
- Handle when `DEFAULT_RESOVE` returns nil

## 0.6.2 (20 Aug 2015)

### Bug fixes

- Fix whitespace parsing in input objects

## 0.6.1 (16 Aug 2015)

### New features

- Parse UTF-8 characters & escaped characters

### Bug fixes

- Properly parse empty strings
- Fix argument / variable compatibility validation


## 0.6.0 (14 Aug 2015)

### Breaking changes & deprecations

- Deprecate `params` option to `Query#new` in favor of `variables`
- Deprecated `.new { |obj, types, fields, args| }` API was removed (use `.define`)

### New features

- `Query#new` accepts `operation_name` argument
- `InterfaceType` and `UnionType` accept `resolve_type` configs

### Bug fixes

- Gracefully handle blank-string & whitespace-only queries
- Handle lists in variable definitions and arguments
- Handle non-null input types

## 0.5.0 (12 Aug 2015)

### Breaking changes & deprecations

- Deprecate definition API that yielded a bunch of helpers #18

### New features

- Add new definition API #18
