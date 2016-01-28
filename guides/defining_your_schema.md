# Defining Your Schema

## Defining Types

### Object Types

Use {GraphQL::ObjectType.define} to define types. Within the block, you can:

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

  # To avoid circular dependencies, pass a String or a Proc for the type.
  # This string will be looked up in the global namespace
  field :sisterCity, "CityType"
  # This proc will be called later, returning `CityType`
  field :country, -> { CountryType }
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

You can rescue errors by defining handlers with {Schema#rescue_from}. The handler should return a string that will be inserted into the response. For example, you can set up a handler:

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


## Middleware

You can use _middleware_ to affect the evaluation of fields in your schema. They function like `before_action`s and `after_action`s in Rails controllers.

A middleware is any object that responds to `#call(*args, next_middleware)`. Inside that method, it should either:

- send `call` to the next middleware to continue the evaluation; or
- return a value to end the evaluation early.

Middlewares' `#call` is invoked with several arguments:

- `parent_type` is the type whose field is being accessed
- `parent_object` is the object being exposed by that type
- `field_definition` is the definition for the field being accessed
- `field_args` is the hash of arguments passed to the field
- `query_context` is the context object passed throughout the query
- `next_middleware` represents the execution chain. Call `#call` to continue evalution.

Add a middleware to a schema by adding to the `#middleware` array.


### Example: Authorization

This middleware only continues evaluation if the `current_user` is permitted to read the target object:

```ruby
class AuthorizationMiddleware
  def call(parent_type, parent_object, field_definition, field_args, query_context, next_middleware)
    current_user = query_context[:current_user] # passed in when creating the query
    if current_user && current_user.can_read?(parent_object)
      # This user is authorized, so continue execution
      next_middleware.call
    else
      # Silently halt execution
      nil
    end
  end
end
```

Then, add the middleware to your schema:

```ruby
MySchema.middleware << AuthorizationMiddleware.new
```

Now, all field access will be wrapped by that authorization routine.
