# Defining Your Schema

## Defining Types

### Object Types

Use `GraphQL::ObjectType.define { ... }` to define types. Within the block, you can:

- define properties: `name`, `description`, `interfaces`
- define fields with the `field` helper
- access the `types` object, which exposes built-in scalar types (`types.Boolean`, `types.Int`, `types.Float`, `types.String`, `types.ID`)

For example:

```ruby
CityType = ObjectType.define do
  name "City"
  description "A large densely populated area"
  interfaces [LocationInterface, NamedEntityInterface]

  field :name, types.String, "The city's name"

  # `!` marks this field as non-null:
  field :population, !types.Int, "Number of people who live in this city"

  # This returns a list of `PersonType`s
  field :mayors, types[PersonType]

  # Avoid the circular dependency by passing a proc
  # The proc will be called later, returning `CityType`
  field :sisterCity, -> { CityType }
end
```

### Other Types

See the test fixtures for an example: https://github.com/rmosolgo/graphql-ruby/blob/master/spec/support/dairy_app.rb

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

## Handling Errors

You can rescue errors by defining handlers with `Schema#rescue_from`. The handler should return a string that will be inserted into the response. For example, you can set up a handler:

```ruby
MySchema.rescue_from(ActiveRecord::RecordInvalid) { "Some data could not be saved" }
```

Then, when a query is executed, that error is rescued and its message is added to the response:

```ruby
result = MySchema.execute(query_string)
# {
#   "data" => {
#     # other fields may resolve successfully
#   },
#   "errors" => [
#     {
#       "message" => "Some data could not be saved",
#       "locations" => [{"line" => 5, "column" => 10}]
#      }
#   ]
# }
```
