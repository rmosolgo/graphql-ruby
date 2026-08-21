# Definition

A GraphQL system is called a _schema_. The schema contains all the types and fields in the system. The schema executes queries and publishes an [introspection system](/schema/introspection).

Your GraphQL schema is a class that extends [GraphQL::Schema](rdoc-ref:GraphQL::Schema), for example:

```ruby
class MyAppSchema < GraphQL::Schema
  max_complexity 400
  query Types::Query
  use GraphQL::Dataloader

  # Define hooks as class methods:
  def self.resolve_type(type, obj, ctx)
    # ...
  end

  def self.object_from_id(node_id, ctx)
    # ...
  end

  def self.id_from_object(object, type, ctx)
    # ...
  end
end
```

There are lots of schema configuration methods. The complete reference is
maintained with the implementation in [GraphQL::Schema](rdoc-ref:GraphQL::Schema),
including root types, object identification, error hooks, limits, introspection,
authorization, tracing, analyzers, and plugins.

The API-specific portions of this page were migrated to the
[GraphQL::Schema](rdoc-ref:GraphQL::Schema) source comments. This page keeps the
setup, lazy-loading, and production walkthroughs.

For defining GraphQL types, see the guides for those types: [object types](/type_definitions/objects), [interface types](/type_definitions/interfaces), [union types](/type_definitions/unions),  [input object types](/type_definitions/input_objects), [enum types](/type_definitions/enums), and [scalar types](/type_definitions/scalars).

## Types in the Schema

See the [GraphQL::Schema API reference](rdoc-ref:GraphQL::Schema) for
root types, orphan types, and extra types. For defining GraphQL types, see the
guides for [object types](/type_definitions/objects), [interface types](/type_definitions/interfaces),
[union types](/type_definitions/unions), [input objects](/type_definitions/input_objects),
[enums](/type_definitions/enums), and [scalars](/type_definitions/scalars).

### Lazy-loading types

In development, GraphQL-Ruby can defer loading your type definitions until they're needed. This requires some configuration to opt in:

- Add `use GraphQL::Schema::Visibility` to your schema. ([GraphQL::Schema::Visibility](rdoc-ref:GraphQL::Schema::Visibility) supports lazy loading and will be the default in a future GraphQL-Ruby version. See [Migration Notes](/authorization/visibility#migration-notes) if you have an existing visibility implementation.)
- Move your entry-point type definitions into a block, for example:

  ```diff
  - query Types::Query
  + query { Types::Query }
  ```

- Optionally, move field types into blocks, too:

  ```diff
  - field :posts, [Types::Post] # Loads `types/post.rb` immediately
  + field :posts do
  +   type([Types::Post]) # Loads `types/post.rb` when this field is used in a query
  + end
  ```

To enforce these patterns, you can enable two Rubocop rules that ship with GraphQL-Ruby:

- `GraphQL/RootTypesInBlock` will make sure that `query`, `mutation`, and `subscription` are all defined in a block.
- `GraphQL/FieldTypeInBlock` will make sure that non-built-in field return types are defined in blocks.

## Object Identification

The [GraphQL::Schema API reference](rdoc-ref:GraphQL::Schema)
documents `object_from_id`, `id_from_object`, and `resolve_type`. For Relay-style
IDs, see [Object Identification](/schema/object_identification); for `loads:`, see
[auto-loading arguments](/mutations/mutation_classes#auto-loading-arguments).

## Error Handling

The [GraphQL::Schema API reference](rdoc-ref:GraphQL::Schema)
describes the error hooks. See the [Type errors guide](/errors/type_errors) and
[error handling guide](/errors/error_handling) for application-level examples.

## Default Limits

See the [GraphQL::Schema API reference](rdoc-ref:GraphQL::Schema)
for depth, complexity, page-size, timeout, error-count, and query-token limits.
The [Complexity and Depth](/queries/complexity_and_depth) and [Timeout](/queries/timeout)
guides show deployment-oriented examples.

## Introspection

The [GraphQL::Schema API reference](rdoc-ref:GraphQL::Schema)
documents `extra_types` and custom introspection namespaces. See the
[introspection guide](/schema/introspection) for a custom introspection system.

## Authorization

The [GraphQL::Schema API reference](rdoc-ref:GraphQL::Schema)
documents the unauthorized object and field hooks. See the
[authorization guide](/authorization/authorization) for the complete authorization flow.

## Execution Configuration

The [GraphQL::Schema API reference](rdoc-ref:GraphQL::Schema)
documents tracing, analyzers, logging, custom execution classes, lazy values, and
plugins. See [Tracing](/queries/tracing), [Analysis](/queries/ast_analysis),
[Logging](/queries/logging), and [lazy execution](/schema/lazy_execution) for
cross-cutting examples.

## Plugins

Use [Schema.use](rdoc-ref:GraphQL::Schema.use) to install plugins such as
[GraphQL::Dataloader](rdoc-ref:GraphQL::Dataloader) and
[GraphQL::Schema::Visibility](rdoc-ref:GraphQL::Schema::Visibility). The plugin
contract is documented in the [GraphQL::Schema API reference](rdoc-ref:GraphQL::Schema).

## Production Considerations

- __Parser caching__: if your application parses GraphQL _files_ (queries or schema definition), it may benefit from enabling [GraphQL::Language::Cache](rdoc-ref:GraphQL::Language::Cache).
- __Eager loading the library__: by default, GraphQL-Ruby autoloads its constants as-needed. In production, they should be eager loaded instead, using `GraphQL.eager_load!`.

  - Rails: enabled automatically. (ActiveSupport calls `.eager_load!`.)
  - Sinatra: add `configure(:production) { GraphQL.eager_load! }` to your application file.
  - Hanami: add `environment(:production) { GraphQL.eager_load! }` to your application file.
  - Other frameworks: call `GraphQL.eager_load!` when your application is booting in production mode.

  See [GraphQL::Autoload#eager_load!](rdoc-ref:GraphQL::Autoload#eager_load!) for more details.
