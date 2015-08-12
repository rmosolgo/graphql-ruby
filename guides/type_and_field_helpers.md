# Type & Field Helpers

`graphql-ruby` includes some helpers to define valid types and fields, although they aren't required.

## Defining Types

Use `GraphQL::ObjectType.define { ... }` to define types. Within the block, you can define a few properties:

- `name`
- `description`
- `interfaces` (accepts an array of `InterfaceType`s)
- `field`, to define a field on this type

You also have access to the `types` object, which exposes built-in scalar types (`types.Boolean`, `types.Int`, `types.Float`, `types.String`, `types.ID`)

## Defining Fields

Usually, you'll define fields while defining a type. The most common case defines a field name, type, and description. For example:

```ruby
field :name, types.String, "The name of this thing"
```

For a more complex definition, you can also pass a definition block. Within the block, you can define `name`, `type`, `description`, `resolve`, and `argument`. For example:

```ruby
field :comments do
  type !types[!CommentType]

  description "Comments on this Post"

  argument :moderated, types.Boolean, default_value: true

  resolve -> (obj, args, ctx) do
     Comment.where(
       post_id: obj.id,
       moderated: args["moderated"]
     )
   end
end
```

This field accepts an optional Boolean argument `moderated`, which it uses to filter results in the `resolve` method.
