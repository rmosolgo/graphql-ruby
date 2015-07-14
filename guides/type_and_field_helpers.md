# Type & Field Helpers

`graphql-ruby` includes some helpers to define valid types and fields, although they aren't required.

## Defining Types

You can use `GraphQL::ObjectType.new { ... }` to define types. The block receives:

1. `t`, the type which is being created.
1. `types`, which provides convenience methods for built-in types.

The type accepts some config methods:

1. `t.name(type_name)` defines the name
1. `t.description(type_desc)` defines the description
1. `t.fields(type_fields)` defines the fields. It accepts a hash of `name => field` values. The keys will be stringified during setting.
1. `t.interfaces(interfaces)` accepts an array of interfaces which this type implements.

## Defining Fields
## The `types` Helper
## The `field` Helper
## The `arg` Helper
