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
  field :sisterCity, CityType
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

In order for your schema to expose members of an interface, it must be able to determine the GraphQL type for a given Ruby object. You must define `resolve_type` in your schema:

```ruby
MySchema = GraphQL::Schema.define do
 # ...
 resolve_type -> (object, ctx) {
   # for example, look up types by class name
   type_name = object.class.name
   MySchema.types[type_name]
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

In order to expose a union, you must also define how the concrete type of each object can be determined. This is defined with `Schema`'s `resolve_type` function (see Interface docs).

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
  input_field :selections, types[ShirtOrderSelectionInput]
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

### Options

A field definition may include some options:

```ruby
field :name, types.String, "The name of this thing",
  # Mark the field as deprecated:
  deprecation_reason: "Nobody calls it by name anymore",
  # Use a different getter method to resolve this field:
  property: :given_name,
  # Count this field as "10" when assessing the cost of running a query
  complexity: 10
```

### Block Definition

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

### Passing an existing field

You can provide a pre-made `GraphQL::Field` object to define a field:

```ruby
name_field = GraphQL::Field.define do
  # ...
end

# ...

field :name, name_field
```

This operation __is destructive__, so you need to use a new `GraphQL::Field` object for each field definition. (The `GraphQL::Field` receives a "name" from the `field` definition.)

## Referencing Types

Some parts of schema definition take types as an input. There are two good ways to provide types:

1. __By value__. Pass a variable which holds the type.

   ```ruby
   # constant
   field :team, TeamType
   # local variable
   field :stadium, stadium_type
   ```

2. __By proc__, which will be lazy-evaluated to look up a type.

   ```ruby
   field :team, -> { TeamType }
   field :stadium, -> { LookupTypeForModel.lookup(Stadium) }
   ```

## Defining the Schema

Your schema can be initialized with some options:

```ruby
MySchema = GraphQL::Schema.define do
  query QueryType,       # root type for read-only queries
  mutation MutationType, # root type for mutations
  max_depth 7,           # if present, the max depth for incoming queries
end
```

Additionally, you can define error handling and custom middleware as described below.

## Handling Errors

You can rescue errors by defining handlers with `Schema#rescue_from`. The handler receives the error instance and it should return a string. The returned string will be added to the `"errors"` key.

For example, you can set up a handler:

```ruby
# The error instance is yielded to the block:
MySchema.rescue_from(ActiveRecord::RecordInvalid) { |error| "Some data could not be saved" }
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

## Query Analyzers

Query analyzers are like middleware for the validation phase. They're called at each node of the query's internal representation (see `GraphQL::InternalRepresentation::Node`). If they return a `GraphQL::AnalysisError`, the query won't be run and the error will be added to the response's `errors` key.

The minimal API is `.call(memo, visit_type, internal_representation_node)`. For example:

```ruby
ast_node_logger = -> (memo, visit_type, internal_representation_node) {
  if visit_type == :enter
    puts "Visiting #{internal_representation_node.name}!"
  end
}
MySchema.query_analyzers << ast_node_logger
```

Whatever `.call(...)` returns will be passed as `memo` for the next visit.

The analyzer can implement a few other methods. If they're present, they'll be called:

- `.initial_value(query)` will be called to generate an initial value for `memo`
- `.final_value(memo)` will be called _after_ visiting the the query

If the last value of `memo` (or the return of `.final_value`) is a `GraphQL::AnalysisError`, the query won't be executed and the error will be added to the `errors` key of the response.

`graphql-ruby` includes a few query analyzers:
- `GraphQL::Analysis::QueryDepth` and `GraphQL::Analysis::QueryComplexity` for inspecting query depth and complexity
- `GraphQL::Analysis::MaxQueryDepth` and `GraphQL::Analysis::MaxQueryComplexity` are used internally to implement `max_depth:` and `max_complexity:` options

### Handling errors

In a query analyzer, you can handle an error in one of two ways:

* You can choose to create an `:errors` key on your memo object. Then, you can push any errors onto it, and return that memoized error:
    ``` ruby
    def initial_value(query)
      {
        :errors => []
      }
    end

    def call(memo, visit_type, irep_node)
      if visit_type == :enter
        memo[:errors] << GraphQL::AnalysisError.new("Just error!", ast_node: irep_node.ast_node)
        end
      end
      memo
    end

    def final_value(memo)
      memo[:errors]
    end
    ```
* You can also `raise GraphQL::AnalysisError`:
    ``` ruby
    def call(memo, visit_type, irep_node)
      if visit_type == :enter
        raise GraphQL::AnalysisError.new("Just error!", ast_node: irep_node.ast_node)
      end
      memo
    end
    ```

## Extending type and field definitions

Types, fields, and arguments have a `metadata` hash which accepts values during definition.

First, make a custom definition:

```ruby
GraphQL::ObjectType.accepts_definitions resolves_to_class_names: GraphQL::Define.assign_metadata_key(:resolves_to_class_names)
# or:
# GraphQL::Field.accepts_definitions(...)
# GraphQL::Argument.accepts_definitions(...)
```


Then, use the custom definition:

```ruby
Post = GraphQL::ObjectType.define do
  # ...
  resolves_to_class_names ["Post", "StaffUpdate"]
end
```

Access `type.metadata` later:

```ruby
MySchema = GraphQL::Schema.define do
  # ...
  # Use the type's declared `resolves_to_class_names`
  # to figure out if `obj` is a member of that type
  resolve_type -> (obj, ctx) {
    class_name = obj.class.name
    MySchema.types.values.find { |type| type.metadata[:resolves_to_class_names].include?(class_name) }
  }
end
```
