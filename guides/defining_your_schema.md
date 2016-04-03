# Defining Your Schema

To define your schema, define types and connect them with fields. Then, initialize your schema with root types (`query` and `mutation`). You can also customize your schema.

## Defining Types

### Object Types

Use `GraphQL::ObjectType.define` to define types. Within the block, you can:

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

### Interface Types

Interfaces provided a set of fields to _many_ object types. When an object includes an interface, it gains the default resolve behavior from that interface.

Interfaces are defined with name, description and fields. For example:

```ruby
BeverageInterface = GraphQL::InterfaceType.define do
  name "Beverage"
  field :caffeinated, types.Boolean
  field :size, BeverageSizeEnum
end

# Then, object types may include it:
CoffeeType = GraphQL::ObjectType.define do
  # ...
  interfaces([BeverageInterface])
end
```

In order for your schema to expose members of an interface, it must be able to determine the GraphQL type for a given Ruby object. `InterfaceType` has a default `resolve_type` definition, or you can provide your own. Here's the default:

```ruby
BeverageInterface = GraphQL::InterfaceType.define do
 # ...
 resolve_type -> (object) {
   type_name = object.class.name
   # you can access the interface's `possible_types` inside the proc
   possible_types.find {|t| t.name == type_name}
 }
end
```

### Union Types

Unions represent a set of object types which may occur in the same place.

```ruby
MediaSearchResultUnion = GraphQL::UnionType.define do
  name "MediaSearchResult"
  description "An object which can be queried by date, location and filesize"
  possible_types [PhotoType, VideoType, AudioType]
end
```

In order to expose a union, you must also define how the concrete type of each object can be determined. `UnionType` provides a default, shown here:

```ruby
MediaSearchResultUnion = GraphQL::UnionType.define do
  # This is the default if you don't provide a custom `resolve_type` proc:
  resolve_type -> (object) {
    type_name = object.class.name
    # You can access the union's `possible_types` inside the proc
    possible_types.find {|t| t.name == type_name}
  }
end
```

### Enum Types

Enums define a set of values which maybe used as returns or inputs for the schema.

Each member of the enum has a _name_ and a value. By default, the name is used as the value. But you can use `value:` to provide a custom value.

Each member may also have a description.

Values can be _deprecated_ by providing a `deprecation_reason:`.

```ruby
ShirtSizeEnum = GraphQL::EnumType.define do
  name "ShirtSize"
  description "T-shirt size"
  value "LARGE", "22 inches wide"
  value "MEDIUM", "20 inches wide"
  value "SMALL", "18 inches wide"
  # Custom value:
  value "X-SMALL", "16 inches wide", value: 0
  # Deprecated value.
  value "XX-SMALL", "14 inches wide", deprecation_reason: "Nobody is this size anymore"
end
```

### Input Object Types

Input objects are complex objects for fields. They may be passed for read operations (such as search queries) or for mutations (such as update payloads).

Input objects are composed of fields. Their fields may contain:

- scalars (eg, boolean, string, int, float)
- enums
- lists
- input objects

```ruby
# Place an order with this input, eg:
# {
#   model_id: "100",
#   selections: [
#     { quantity: 1, size: LARGE },
#     { quantity: 4, size: MEDIUM },
#     { quantity: 3, size: SMALL },
#   ] ,
# }

ShirtOrderInput = GraphQL::InputObjectType.define do
  name "ShirtOrder"
  description "An order for some t-shirts"
  input_field :model_id, !types.ID
  # A list of other inputs:
  input_field :selections, -> { types[ShirtOrderSelectionInput] }
end

ShirtOrderSelectionInput = GraphQL::InputObjectType.define do
  name "ShirtOrderSelection"
  description "A quantity & size to order for a given shirt"
  input_field :quantity, !types.Int
  input_field :size, !ShirtSizeEnum
end
```

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

## Defining the Schema

Your schema can be initialized with some options:

```ruby
MySchema = GraphQL::Schema.new(
  query: QueryType,       # root type for read-only queries
  mutation: MutationType, # root type for mutations
  max_depth: 7,           # if present, the max depth for incoming queries
)
```

Additionally, you can define error handling and custom middleware as described below.

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

When explicitly raising the exception, you can raise a `GraphQL::ExecutionError` with a message to add to the response without specifying an error handler.

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
