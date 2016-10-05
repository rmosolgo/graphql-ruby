# Changelog

### Breaking changes

### Deprecations

### New features

### Bug fixes

## 0.19.1 (4 Oct 2016)

### Breaking changes

- Previously-deprecated `InterfaceType#resolve_type` hook has been removed, use `Schema#resolve_type` instead #290

### New features

- Eager-load schemas at definition time, validating types & schema-level hooks #289
- `InvalidNullError`s contain the type & field name that returned null #293
- If an object is resolved with `Schema#resolve_type` and the resulting type is not a member of the expected possible types, raise an error #291

### Bug fixes

- Allow `directive` as field or argument name #288

## 0.19.0 (30 Sep 2016)

### Breaking changes

- `GraphQL::Relay::GlobalNodeIdentification` was removed. Its features were moved to `GraphQL::Schema` or `GraphQL::Relay::Node`. The new hooks support more robust & flexible global IDs. #243

  - Relay's `"Node"` interface and `node(id: "...")` field were both moved to `GraphQL::Relay::Node`. To use them in your schema, call `.field` and `.interface`. For example:

    ```ruby
    # Adding a Relay-compliant `node` field:
    field :node, GraphQL::Relay::Node.field
    ```

    ```ruby
    # This object type implements Relay's `Node` interface:
    interfaces [GraphQL::Relay::Node.interface]
    ```

  - UUID hooks were renamed and moved to `GraphQL::Schema`. You should define `id_from_object` and `object_from_id` in your `Schema.define { ... }` block. For example:

    ```ruby
    MySchema = GraphQL::Schema.define do
      # Fetch an object by UUID
      object_from_id -> (id, ctx) {
        MyApp::RelayLookup.find(id)
      }
      # Generate a UUID for this object
      id_from_object -> (obj, type_defn, ctx) {
        MyApp::RelayLookup.to_id(obj)
      }
    end
    ```

  - The new hooks have no default implementation. To use the previous default, use `GraphQL::Schema::UniqueWithinType`, for example:

      ```ruby
      MySchema = GraphQL::Schema.define do
        object_from_id -> (id, ctx) {
          # Break the id into its parts:
          type_name, object_id = GraphQL::Schema::UniqueWithinType.decode(id)
          # Fetch the identified object
          # ...
        }

        id_from_object -> (obj, type_defn, ctx) {
          # Provide the the type name & the object's `id`:
          GraphQL::Schema::UniqueWithinType.encode(type_defn.name, obj.id)
        }
      end
      ```

      If you were using a custom `id_separator`, it's now accepted as an input to `UniqueWithinType`'s  methods, as `separator:`. For example:

      ```ruby
      # use "---" as a ID separator
      GraphQL::Schema::UniqueWithinType.encode(type_name, object_id, separator: "---")
      GraphQL::Schema::UniqueWithinType.decode(relay_id, separator: "---")
      ```

  - `type_from_object` was previously deprecated and has been replaced by `Schema#resolve_type`. You should define this hook in your schema to return a type definition for a given object:

    ```ruby
    MySchema = GraphQL::Schema.define do
      # ...
      resolve_type -> (obj, ctx) {
        # based on `obj` and `ctx`,
        # figure out which GraphQL type to use
        # and return the type
      }
    end
    ```

  - `Schema#node_identification` has been removed.

- `Argument` default values have been changed to be consistent with `InputObjectType` default values. #267

  Previously, arguments expected GraphQL values as `default_value`s. Now, they expect application values.   (`InputObjectType`s always worked this way.)

  Consider an enum like this one, where custom values are provided:

  ```ruby
  PowerStateEnum = GraphQL::EnumType.define do
    name "PowerState"
    value("ON", value: 1)
    value("OFF", value: 0)
  end
  ```

  __Previously__, enum _names_ were provided as default values, for example:

  ```ruby
  field :setPowerState, PowerStateEnum do
    # Previously, the string name went here:
    argument :newValue, default_value: "ON"
  end
  ```

  __Now__, enum _values_ are provided as default values, for example:

  ```ruby
  field :setPowerState, PowerStateEnum do
    # Now, use the application value as `default_value`:
    argument :newValue, default_value: 1
  end
  ```

  Note that if you __don't have custom values__, then there's no change, because the name and value are the same.

  Here are types that are affected by this change:

  - Custom scalars (previously, the `default_value` was a string, now it should be the application value, eg `Date` or `BigDecimal`)
  - Enums with custom `value:`s (previously, the `default_value` was the name, now it's the value)

  If you can't replace `default_value`s, you can also use a type's `#coerce_input` method to translate a GraphQL value into an application value. For example:

  ```ruby
  # Using a custom scalar, "Date"
  # PREVIOUSLY, provide a string:
  argument :starts_on, DateType, default_value: "2016-01-01"
  # NOW, transform the string into a Date:
  argument :starts_on, DateType, default_value: DateType.coerce_input("2016-01-01")
  ```

### New features

- Support `@deprecated` in the Schema language #275
- Support `directive` definitions in the Schema language  #280
- Use the same introspection field descriptions as `graphql-js` #284

### Bug fixes

- Operation name is no longer present in execution error `"path"` values #276
- Default values are correctly dumped & reloaded in the Schema language #267

## 0.18.15 (20 Sep 2016)

### Breaking changes

- Validation errors no longer have a `"path"` key in their JSON. It was renamed to `"fields"` #264
- `@skip` and `@include` over multiple selections are handled according to the spec: if the same field is selected multiple times and _one or more_ of them would be included, the field will be present in the response. Previously, if _one or more_ of them would be skipped, it was absent from the response. #256

### New features

- Execution errors include a `"path"` key which points to the field in the response where the error occurred. #259
- Parsing directives from the Schema language is now supported #273


### Bug fixes

- `@skip` and `@include` over multiple selections are now handled according to the spec #256

## 0.18.14 (20 Sep 2016)

### Breaking changes

- Directives are no longer considered as "conflicts" in query validation. This is in conformity with the spec, but a change for graphql-ruby #263

### Features

- Query analyzers may emit errors by raising `GraphQL::AnalysisError`s during `#call` or returning a single error or an array of errors from `#final_value` #262

### Bug fixes

- Merge fields even when `@skip` / `@include` are not identical #263
- Fix possible infinite loop in `FieldsWillMerge` validation #261

## 0.18.13 (19 Sep 2016)

### Bug fixes

- Find infinite loops in nested contexts, too #258

## 0.18.12 (19 Sep 2016)

### New features

- `GraphQL::Analysis::FieldUsage` can be used to check for deprecated fields in the query analysis phase #245

### Bug fixes

- If a schema receives a query on `mutation` or `subscription` but that root doesn't exist, return a validation error #254
- `Query::Arguments#to_h` only includes keys that were provided in the query or have a default value #251


## 0.18.11 (11 Sep 2016)

### New features

- `GraphQL::Language::Nodes::Document#slice(operation_name)` finds that operation and its dependencies and puts them in a new `Document` #241

### Bug fixes

- Validation errors for non-existent fields have the location of the field usage, not the parent field #247
- Properly `require "forwardable"` #242
- Remove `ALLOWED_CONSTANTS` for boolean input, use a plain comparison #240

## 0.18.10 (9 Sep 2016)

### New features

- Assign `#mutation` on objects which are derived from a `Relay::Mutation` #239

## 0.18.9 (6 Sep 2016)

### Bug fixes

- fix backward compatibility for `type_from_object` #238

## 0.18.8 (6 Sep 2016)

### New features

- AST nodes now respond to `#eql?(other)` to test value equality #231

### Bug fixes

- The `connection` helper no longer adds a duplicate field #235

## 0.18.7 (6 Sep 2016)

### New features

- Support parsing nameless fragments (but not executing them) #232

### Bug fixes

- Allow `__type(name: "Whatever")` to return null, as per the spec #233
- Include a Relay mutation's description with a mutation field #225

## 0.18.6 (29 Aug 2016)

### New features

- ` GraphQL::Schema::Loader.load(schema_json)` turns an introspection result into a `GraphQL::Schema` #207
- `.define` accepts plural definitions for: object fields, interface fields field arguments, enum values #222

## 0.18.5 (27 Aug 2016)

### Deprecations

- `Schema.new` is deprecated; use `Schema.define` instead.

  Before:

  ```ruby
  schema = GraphQL::Schema.new(
    query: QueryType,
    mutation: MutationType,
    max_complexity: 100,
    types: [ExtraType, OtherType]
  )
  schema.node_identification = MyGlobalID
  schema.rescue_from(ActiveRecord::RecordNotFound) { |err| "..." }
  ```

  After:

  ```ruby
  schema = GraphQL::Schema.define do
    query QueryType
    mutation MutationType
    max_complexity 100
    node_identification MyGlobalID
    rescue_from(ActiveRecord::RecordNotFound) { |err| "..." }
    # Types was renamed to `orphan_types` to avoid conflict with the `types` helper
    orphan_types [ExtraType, OtherType]
  end
  ```

  This unifies the disparate methods of configuring a schema and provides new, more flexible design space. It also adds `#metadata` to schemas for user-defined storage.

- `UnionType#resolve_type`, `InterfaceType#resolve_type`, and `GlobalNodeIdentification#type_from_object` are deprecated, unify them into `Schema#resolve_type` instead.

  Before:

  ```ruby
  GraphQL::Relay::GlobalNodeIdentification.define do
    type_from_object -> (obj) { ... }
  end

  GraphQL::InterfaceType.define do
    resolve_type -> (obj, ctx) { ... }
  end
  ```

  After:

  ```ruby
  GraphQL::Schema.define do
    resolve_type -> (obj, ctx) { ... }
  end
  ```

  This simplifies type inference and prevents unexpected behavior when different parts of the schema resolve types differently.

### New features

- Include expected type in Argument errors #221
- Define schemas with `Schema.define` #208
- Define a global object-to-type function with `Schema#resolve_type` #216

### Bug fixes

## 0.18.4 (25 Aug 2016)

### New features

- `InvalidNullError`s expose a proper `#message` #217

### Bug fixes

- Return an empty result for queries with no operations #219

## 0.18.3 (22 Aug 2016)

### Bug fixes

- `Connection.new(:field)` is optional, not required #215
- 0.18.2 introduced a more restrictive approach to resolving interfaces & unions; revert that approach #212

## 0.18.2 (17 Aug 2016)

### New features

- Connection objects expose the `GraphQL::Field` that created them via `Connection#field` #206

## 0.18.1 (7 Aug 2016)

### Deprecations

- Unify `Relay` naming around `nodes` as the items of a connection:
  - `Relay::BaseConnection.connection_for_nodes` replaces `Relay::BaseConnection.connection_for_items`
  - `Relay::BaseConnection#nodes` replaces `Relay::BaseConnection#object`

### New features

- Connection fields' `.resolve_proc` is an instance of `Relay::ConnectionResolve` #204
- Types, fields and arguments can store arbitrary values in their `metadata` hashes #203

## 0.18.0 (4 Aug 2016)

### Breaking changes

- `graphql-relay` has been merged with `graphql`, you should remove `graphql-relay` from your gemfile. #195

### Deprecations

### New features

- `GraphQL.parse` can turn schema definitions into a `GraphQL::Language::Nodes::Document`. The document can be stringified again with `Document#to_query_string` #191
- Validation errors include a `path` to the part of the query where the error was found #198
- `.define` also accepts keywords for each helper method, eg `GraphQL::ObjectType.define(name: "PostType", ...)`

### Bug fixes

- `global_id_field`s have default complexity of 1, not `nil`
- Relay `pageInfo` is correct for connections limited by `max_page_size`
- Rescue invalid variable errors & missing operation name errors during query analysis

## 0.17.2 (26 Jul 2016)

### Bug fixes

- Correctly spread fragments when nested inside other fragments #194

## 0.17.1 (26 Jul 2016)

### Bug fixes

- Fix `InternalRepresentation::Node#inspect`

## 0.17.0 (21 Jul 2016)

### Breaking changes

- `InternalRepresentation::Node` API changes:

  - `#definition_name` returns the field name on field nodes (while `#name` may have an alias)
  - `#definitions` returns `{type => field}` pairs for possible fields on this node
  - `#definition` is gone, it is equivalent to `node.definitions.values.first`
  - `#on_types` is gone, it is equivalent to `node.definitions.keys`

### New features

- Accept `hash_key:` field option
- Call `.define { }` block lazily, so `-> { }` is not needed for circular references #182

### Bug fixes

- Support `on` as an Enum value
- If the same field is requested on multiple types, choose the maximum complexity among them (not the first)

## 0.16.1 (20 Jul 2016)

### Bug fixes

- Fix merging fragments on Union types (see #190, broken from #180)

## 0.16.0 (14 Jul 2016)

### Breaking changes & deprecations

- I don't _know_ that this breaks anything, but  `GraphQL::Query::SerialExecution` now iterates over a tree of `GraphQL::InternalRepresentation::Node`s instead of an AST (`GraphQL::Language::Nodes::Document`).

### New features

- Query context keys can be assigned with `Context#[]=` #178
- Cancel further field resolution with `TimeoutMiddleware` #179
- Add `GraphQL::InternalRepresentation` for normalizing queries from AST #180
- Analyze the query before running it #180
- Assign complexity cost to fields, enforce max complexity before running it #180
- Log max complexity or max depth with `MaxComplexity` or `MaxDepth` analyzers #180
- Query context exposes `#irep_node`, the internal representation of the current node #180

### Bug fixes

- Non-null errors are propagated to the next nullable field, all the way up to `data` #174

## 0.15.3 (28 Jun 2016)

### New features

- `EnumValue`s can receive their properties after instantiation #171

## 0.15.2 (16 Jun 2016)

### New features

- Support lazy type arguments in Object's `interfaces` and Union's `possible_types` #169

### Bug fixes

- Support single-member Unions, as per the spec #170

## 0.15.1 (15 Jun 2016)

### Bug fixes

- Whitelist operation types in `lexer.rb`

## 0.15.0 (11 Jun 2016)

### Breaking changes & deprecations

- Remove `debug:` option, propagate all errors. #161

## 0.14.1 (11 Jun 2016)

### Breaking changes & deprecations

- `debug:` is deprecated (#165). Propagating errors (`debug: true`) will become the default behavior. You can get a similar implementation of error gobbling with `CatchallMiddleware`. Add it to your schema:

    ```ruby
    MySchema.middleware << GraphQL::Schema::CatchallMiddleware
    ```

### New features

### Bug fixes

- Restore previous introspection fields on DirectiveType as deprecated #164
- Apply coercion to input default values #162
- Proper Enum behavior when a value isn't found

## 0.14.0 (31 May 2016)

### Breaking changes & deprecations

### New features

- `GraphQL::Language::Nodes::Document#to_query_string` will re-serialize a query AST #151
- Accept `root_value:` when running a query #157
- Accept a `GraphQL::Language::Nodes::Document` to `Query.new` (this allows you to cache parsed queries on the server) #152

### Bug fixes

- Improved parse error messages #149
- Improved build-time validation #150
- Raise a meaningful error when a Union or Interface can't be resolved during query execution #155

## 0.13.0 (29 Apr 2016)

### Breaking changes & deprecations

- "Dangling" object types are not loaded into the schema. The must be passed in `GraphQL::Schema.new(types: [...])`. (This was deprecated in 0.12.1)

### New features

- Update directive introspection to new spec #121
- Improved schema validation errors #113
- 20x faster parsing #119
- Support inline fragments without type condition #123
- Support multiple schemas composed of the same types #142
- Accept argument `description` and `default_value` in the block #138
- Middlewares can send _new_ arguments to subsequent middlewares #129

### Bug fixes

- Don't leak details of internal errors #120
- Default query `context` to `{}` #133
- Fixed list nullability validation #131
- Ensure field names are strings #128
- Fix `@skip` and `@include` implementation #124
- Interface membership is not shared between schemas #142

## 0.12.1 (26 Apr 2016)

### Breaking changes & deprecations

- __Connecting object types to the schema _only_ via interfaces is deprecated.__ It will be unsupported in the next version of `graphql`.

  Sometimes, object type is only connected to the Query (or Mutation) root by being a member of an interface. In these cases, bugs happen, especially with Rails development mode. (And sometimes, the bugs don't appear until you deploy to a production environment!)

  So, in a case like this:

  ```ruby
  HatInterface = GraphQL::ObjectType.define do
    # ...
  end

  FezType = GraphQL::ObjectType.define do
    # ...
    interfaces [HatInterface]
  end

  QueryType = GraphQL::ObjectType.define do
    field :randomHat, HatInterface # ...
  end
  ```

  `FezType` can only be discovered by `QueryType` _through_ `HatInterface`. If `fez_type.rb` hasn't been loaded by Rails, `HatInterface.possible_types` will be empty!

  Now, `FezType` must be passed to the schema explicitly:

  ```ruby
  Schema.new(
    # ...
    types: [FezType]
  )
  ```

  Since the type is passed directly to the schema, it will be loaded right away!

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
