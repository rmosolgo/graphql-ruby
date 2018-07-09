---
layout: guide
doc_stub: false
search: true
section: Type Definitions
title: Objects
desc: Objects expose data and link to other objects
index: 0
class_based_api: true
---

GraphQL object types are the bread and butter of GraphQL APIs. Each object has _fields_ which expose data and may be queried by name. For example, we can query a `User` like this:

```ruby
user {
  handle
  email
}
```

And get back values like this:

```ruby
{
  "user" => {
    "handle" => "rmosolgo",
    "email" => nil,
  }
}
```

Generally speaking, GraphQL object types correspond to models in your application, like `User`, `Product`, or `Comment`.  Sometimes, object types are described using the [GraphQL Schema Definition Language](http://graphql.org/learn/schema/#type-language) (SDL):

```ruby
type User {
  email: String
  handle: String!
  friends: [User!]!
}
```

This means that `User` objects have three fields:

- `email`, which may return a `String` _or_ `nil`.
- `handle`, which returns a `String` but _never_ `nil` (`!` means the field never returns `nil`)
- `friends`, which returns a list of other `User`s (`[...]` means the field returns a list of values; `User!` means the list contains `User` objects, and never contains `nil`.)

The same object can be defined using Ruby:

```ruby
class User < GraphQL::Schema::Object
  field :email, String, null: true
  field :handle, String, null: false
  field :friends, [User], null: false
end
```

The rest of this guide will describe how to define GraphQL object types in Ruby. To learn more about GraphQL object types in general, see the [GraphQL docs](http://graphql.org/learn/schema/#object-types-and-fields).

## Object classes

Classes extending {{ "GraphQL::Schema::Object" | api_doc }} describe [Object types](http://graphql.org/learn/schema/#object-types-and-fields) and customize their behavior.

Object fields can be created with the `field(...)` class method, [described in detail below](#fields)

Field and argument names should be underscored as a convention. They will be converted to camelCase in the underlying GraphQL type and be camelCase in the schema itself.

```ruby
# first, somewhere, a base class:
class Types::BaseObject < GraphQL::Schema::Object
end

# then...
class Types::TodoList < Types::BaseObject
  description "A list of items which may be completed"

  field :name, String, "The unique name of this list", null: false
  field :is_completed, String, "Completed status depending on all tasks being done.", null: false
  # Related Object:
  field :owner, Types::User, "The creator of this list", null: false
  # List field:
  field :viewers, [Types::User], "Users who can see this list", null: false
  # Connection:
  field :items, Types::TodoItem.connection_type, "Tasks on this list", null: false do
    argument :status, TodoStatus, "Restrict items to this status", required: false
  end
end
```

## Fields

Object fields expose data about that object or connect the object to other objects. You can add fields to your object types with the `field(...)` class method, for example:

```ruby
field :name, String, "The unique name of this list", null: false
```

The different elements of field definition are addressed below:

- [Return types](#field-return-type) say what kind of data this field returns
- [Documentation](#field-documentation) includes description and deprecation notes
- [Resolution behavior](#field-resolution) hooks up Ruby code to the GraphQL field
- [Arguments](#field-arguments) allow fields to take input when they're queried
- [Extra field metadata](#extra-field-metadata) for low-level access to the GraphQL-Ruby runtime
- [Add default values for field parameters](#field-parameter-default-values)

### Field Return Type

The second argument to `field(...)` is the return type. This can be:

- A built-in GraphQL type (`Integer`, `Float`, `String`, `ID`, or `Boolean`)
- A GraphQL type from your application
- An _array_ of any of the above, which denotes a {% internal_link "list type", "/type_definitions/lists" %}.

{% internal_link "Nullability", "/type_definitions/non_nulls" %} is expressed with the required `null:` keyword:

- `null: true` means that the field _may_ return `nil`
- `null: false` means the field is non-nullable; it may not return `nil`. If the implementation returns `nil`, GraphQL-Ruby will return an error to the client.

Additionally, list types maybe nullable by adding `[..., null: true]` to the definition.

Here are some examples:

```ruby
field :name, String, null: true # `String`, may return a `String` or `nil`
field :id, ID, null: false # `ID!`, always returns an `ID`, never `nil`
field :teammates, [Types::User], null: false # `[User!]!`, always returns a list containing `User`s
field :scores, [Integer, null: true], null: true # `[Int]`, may return a list or `nil`, the list may contain a mix of `Integer`s and `nil`s
```

### Field Documentation

Fields maybe documented with a __description__ and may be __deprecated__.

__Descriptions__ can be added with the `field(...)` method as a positional argument, a keyword argument, or inside the block:

```ruby
# 3rd positional argument
field :name, String, "The name of this thing", null: false
# `description:` keyword
field :name, String, null: false, description: "The name of this thing"
# inside the block
field :name, String, null: false do
  description "The name of this thing"
end
```

__Deprecated__ fields can be marked by adding a `deprecation_reason:` keyword argument:

```ruby
field :email, String, null: true, deprecation_reason: "Users may have multiple emails, use `User.emails` instead."
```

Fields with a `deprecation_reason:` will appear as "deprecated" in GraphiQL.

### Field Resolution

In general, fields return Ruby values corresponding to their GraphQL return types. For example, a field with the return type `String` should return a Ruby string, and a field with the return type `[User!]!` should return a Ruby array with zero or more `User` objects in it.

By default, fields return values by:

- Trying to call a method on the underlying object; _OR_
- If the underlying object is a `Hash`, lookup a key in that hash.

The method name or hash key corresponds to the field name, so in this example:

```ruby
field :top_score, Integer, null: false
```

The default behavior is to look for a `#top_score` method, or lookup a `Hash` key, `:top_score` (symbol) or `"top_score"` (string).

You can override the method name with the `method:` keyword, or override the hash key with the `hash_key:` keyword, for example:

```ruby
# Use the `#best_score` method to resolve this field
field :top_score, Integer, null: false, method: :best_score
# Lookup `hash["allPlayers"]` to resolve this field
field :players, [User], null: false, hash_key: "allPlayers"
```

If you don't want to delegate to the underlying object, you can define a method for each field:

```ruby
# Use the custom method below to resolve this field
field :total_games_played, Integer, null: false

def total_games_played
  object.games.count
end
```

Inside the method, you can access some helper methods:

- `object` is the underlying application object (formerly `obj` to resolve functions)
- `context` is the query context (passed as `context:` when executing queries, formerly `ctx` to resolve functions)

Additionally, when you define arguments (see below), they're passed to the method definition, for example:

```ruby
# Call the custom method with incoming arguments
field :current_winning_streak, Integer, null: false do
  argument :include_ties, Boolean, required: false, default_value: false
end

def current_winning_streak(include_ties:)
  # Business logic goes here
end
```

### Field Arguments

_Arguments_ allow fields to take input to their resolution. For example:

- A `search()` field may take a `term:` argument, which is the query to use for searching, eg `search(term: "GraphQL")`
- A `user()` field may take an `id:` argument, which specifies which user to find, eg `user(id: 1)`
- An `attachments()` field may take a `type:` argument, which filters the result by file type, eg `attachments(type: PHOTO)`

Arguments can be expressed in the SDL:

```ruby
type User {
  # This user's transaction history, after `since` if present.
  transactions(since: DateTime): [Transaction!]!
}
```

Arguments are _typed_, so each argument takes a certain kind of data. Only a few types are valid inputs:

- {% internal_link "Scalars", "/type_definitions/scalars" %}, such as `String`, `Integer`, `Float`, `Boolean`, `ID`, or custom scalar types
- {% internal_link "Enums", "/type_definitions/enums" %}, defined by your application
- {% internal_link "Input objects", "/type_definitions/input_objects" %}, defined by your application
- {% internal_link "Lists", "/type_definitions/lists" %} of any of the above type

(Objects, interfaces, and unions are _not_ valid input types.)

To add arguments to fields, use the `argument(...)` method, inside a block:

```ruby
field :transactions, [Types::Transaction], null: false do
  argument :since, Types::DateTime, required: false
end
```

If an argument has `required: true`, then all queries to the field _must_ provide a value for that argument. `required: false` means that the argument is optional. (This is called {% internal_link "nullability", "/type_definitions/non_nulls" %} in GraphQL.)

Arguments can also accept a description and a `default_value:`, for example:

```ruby
field :transactions, [Types::Transaction], null: false do
  # Description is added after the type name or the `description:` keyword argument
  # By default, `isCompleted: true` will be used
  argument :is_completed, Boolean, "Filter by completed/incompleted status", required: false, default: true
end
```

During field resolution, arguments are passed to the object's method. So, for `transactions` above:

```ruby
# In GraphQL, `transactions(isCompleted: true)` will become:
def transactions(is_completed:)
  p is_completed
  # => true
  # ...
end
```

So, each argument corresponds to a keyword in the method. Inside the method, you can use those values to search, filter and perform business logic for your field.

### Extra Field Metadata

Inside a field method, you can access some low-level objects from the GraphQL-Ruby runtime. Be warned, these APIs are subject to change, so check the changelog when updating.

A few `extras` are available:

- `irep_node`
- `ast_node`
- `parent`, the parent field context
- `execution_errors`, whose `#add(err_or_msg)` method should be used for adding errors

To inject them into your field method, first, add the `extras:` option to the field definition:

```ruby
field :my_field, String, null: false, extras: [:irep_node]
```

Then add `irep_node:` keyword to the method signature:

```ruby
def my_field(irep_node:)
  # ...
end
```

At runtime, the requested runtime object will be passed to the field.

### Field Parameter Default Values 

The field method requires you to pass `null:` keyword argument to determine whether the field is nullable or not. Another field you may want to overrid is `camelize`, which is `true` by default. You can override this behavior by adding a custom field. 

```ruby
class CustomField < GraphQL::Schema::Field
  # Add `null: false` and `camelize: false` which provide default values 
  # in case the caller doesn't pass anything for those arguments. 
  # **kwargs is a catch-all that will get everything else 
  def initialize(*args, null: false, camelize: false, **kwargs, &block)
    # Then, call super _without_ any args, where Ruby will take 
    # _all_ the args originally passed to this method and pass it to the super method.
    super 
  end
end
```

## Implementing interfaces

If an object implements any interfaces, they can be added with `implements`, for example:

```ruby
# This object implements some interfaces:
implements GraphQL::Relay::Node.interface
implements Types::UserAssignableType
```

When an object `implements` interfaces, it:

- inherits the GraphQL field definitions from that object
- includes that module into the object definition

Read more about interfaces in the {% internal_link "Interfaces guide", "/type_definitions/interfaces" %}
