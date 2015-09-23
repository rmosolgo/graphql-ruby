# Defining Your Schema

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

## Handling Errors

If you want to send errors back in the response, you can return a `GraphQL::ExecutionError` from your field's `resolve` method. This will cause the message to be added to the response, along with the location of that field in the query string. Other fields can be resolved as normal.

For example:


```ruby
field :errorsIfNegative, types.Int, "Returns an error if the input is less than 0" do
  argument :number, types.Int
  resolve -> (object, args, ctx) {
    input = args[:number]
    if input < 0
      # Handle a special case by returning an error:
      GraphQL::ExecutionError.new("'errorsIfNegative' Can't handle negative inputs")
    else
      input
    end
  }
end
```

This will cause the `"errors"` key in the result to have that message:

```ruby
result = MySchema.execute(query_string)
# {
#   "data" => {
#     # other fields may resolve successfully
#   },
#   "errors" => [
#     {
#       "message" => "'errorsIfNegative' Can't handle negative inputs",
#       "locations" => [{"line" => 5, "column" => 10}]
#      }
#   ]  
# }
```
