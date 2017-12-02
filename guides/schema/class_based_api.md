---
layout: guide
search: true
section: Schema
title: Class-based API
desc: Define your GraphQL schema with Ruby classes (1.8.x alpha releases)
experimental: true
index: 10
---

In GraphQL `1.8`+, you can use Ruby classes to build your schema. You can __mix__ class-style and `.define`-style type definitions in a schema.

(`1.8` is currently in prerelease, check [RubyGems](https://rubygems.org/gems/graphql) for the latest version.)

You can get an overview of this new feature:

- [Rationale & Goals](#rationale--goals)
- [Compatibility & Migration Overview](#compatibility--migration-overview)
- [Roadmap](#roadmap)

And learn about the APIs:

- [Schema class](#schema-class)
- [Common type configurations](#common-type-configurations) (shared by all the following types)
- [Object classes](#object-classes)
- [Interface classes](#interface-classes)
- [Union classes](#union-classes)
- [Enum classes](#enum-classes)
- [Input Object classes](#input-object-classes)
- [Scalar classes](#scalar-classes)
- [Customizing definitions](#customizing-definitions)


## Rationale & Goals

This new API aims to improve the "getting started" experience and the schema customization experience by replacing GraphQL-Ruby-specific DSLs with familiar Ruby semantics (classes and methods).

Additionally, this new API must be cross-compatible with the current schema definition API so that it can be adopted bit-by-bit.

## Compatibility & Migration overview

Parts of your schema can be converted one-by-one, so you can convert definitions gradually.

### Classes

In general, each `.define { ... }` block will be converted to a class.

- Instead of a `GraphQL::{X}Type`, classes inherit from `GraphQL::Schema:{X}`. For example, instead of `GraphQL::ObjectType.define { ... }`, a definition is made by extending `GraphQL::Schema::Object`
- Any class hierarchy is supported; It's recommended to create a base class for your application, then extend the base class for each of your types (like `ApplicationController` in Rails, see [Customizing Definitions](#customizing-defintions)).

See sections below for specific information about each schema definition class.

### Type Instances

The previous `GraphQL::{X}Type` objects are still used under the hood. Each of the new `GraphQL::Schema::{X}` classes implements a few methods:

- `.to_graphql`: creates a new instance of `GraphQL::{X}Type`
- `.graphql_definition`: returns a cached instance of `GraphQL::{X}Type`

If you have custom code which breaks on new-style definitions, try calling `.graphql_definition` to get the underlying type object.

As described below, `.to_graphql` can be overridden to customize the type system.

### List Types and Non-Null Types

Previously, list types were expressed with `types[T]` and non-null types were expressed with `!T`. Now:

- List types are expressed with Ruby Arrays, `[T]`, for example, `field :owners, [Types::UserType]`
- Non-null types are expressed with keyword arguments `null:` or `required:`
  - `field` takes a keyword `null:`. `null: true` means the field is nullable, `null: false` means the field is non-null (equivalent to `!`)
  - `argument` takes a keyword `required:`. `required: true` means the argument is non-null (equivalent to `!`), `required: false` means that the argument is nullable

In legacy-style classes, you may also use plain Ruby methods to create list and non-null types:

- `#to_non_null_type` converts a type to a non-null variant (ie, `T.to_non_null_type` is equivalent to `!T`)
- `#to_list_type` converts a type to a list variant (ie, `T.to_list_type` is equivalent to `types[T]`)

The `!` method has been removed to avoid ambiguity with the built-in logical operator and related foot-gunning.

For compatibility, you may wish to backport `!` to class-based type definitions. You have two options:

__A refinement__, activated in [file scope or class/module scope](https://docs.ruby-lang.org/en/2.4.0/syntax/refinements_rdoc.html#label-Scope):

```ruby
# Enable `!` method in this scope
using GraphQL::DeprecatedDSL
```

__A monkeypatch__, activated in global scope:

```ruby
# Enable `!` everywhere
GraphQL::DeprecatedDSL.activate
```

## Roadmap

Here is a working plan for rolling out this feature:

- ongoing:
  - ☐ Receive feedback from GraphQL schema owners about the new API (usability & goals)
- graphql 1.8:
  - ☑ Build a schema definition API based on classes instead of singletons
  - ☑ Migrate a few components of GitHub's GraphQL schema to this new API
  - ☐ Build advanced class-based features:
    - ☐ Custom `Context` classes
    - ☐ Custom introspection types
    - ☐ Custom directives
    - ☐ Custom `Schema#execute` method
  - ☐ Migrate all of GitHub's GraphQL schema to this new API
- graphql 1.9:
  - ☐ Update all GraphQL-Ruby docs to reflect this new API
- graphql 1.10:
  - ☐ Begin sunsetting `.define`: isolate it in its own module
  - ☐ Remove `.define`

## Schema class

Your GraphQL schema is a class that extends {{ "GraphQL::Schema" | api_doc }}. Its configuration options are similar to `.define`-based options, but if you find something that doesn't work, please {% open_an_issue "Class-based schema issue","(Please share some example code and the error you found)" %}.

```ruby
class MyAppSchema < GraphQL::Schema
  max_complexity 400
  query Types::Query
  use GraphQL::Batch

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

## Common Type Configurations

Some configurations are used for _all_ types described below:

- `graphql_name` overrides the type name. (The default value is the Ruby constant name, without any namespaces)
- `description` provides a description for GraphQL introspection.

For example:

```ruby
class Types::TodoList < GraphQL::Schema::Object # or Scalar, Enum, Union, whatever
  graphql_name "List" # Overrides the default of "TodoList"
  description "Things to do (may have already been done)"
end
```

(Implemented in {{ "GraphQL::Schema::Member" | api_doc }}).

## Object classes

Classes extending {{ "GraphQL::Schema::Object" | api_doc }} describe [Object types](http://graphql.org/learn/schema/#object-types-and-fields) and customize their behavior.

Object fields can be created with the `field(...)` class method, which accepts the similar arguments as the previous `field(...)` method.

Field and argument names should be underscored as a convention. They will be converted to camelCase in the underlying GraphQL type and be camelCase in the schema itself.

```ruby
# first, somewhere, a base class:
class Types::BaseObject < GraphQL::Schema::Object
end

# then...
class Types::TodoList < Types::BaseObject
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

### New return type & argument type specification

The second argument to `field(...)` is the return type. This can be:

- A GraphQL type object built with `.define { ... }`
- A GraphQL type class which you defined
- A Ruby constant such as `Integer`, `Float`, `String`, `ID`, or `Boolean` (these correspond to GraphQL built-in scalars)
- An _array_ of any of the above, which denotes a list type. Inner list types are always made non-null.

Nullability is expressed with the required `null:`/`required:` keywords:

- Fields require the keyword `null:`
  - `null: true` means that the field _may_ return null
  - `null: false` means the field is non-nullable; it may not return null. If the implementation returns `nil`, GraphQL-Ruby will return an error to the client.
- Arguments require the keyword `required:`
  - `required: true` means the argument must be provided (the type is non-null)
  - `required: false` means the argument is optional (the type is nullable)

Here are some examples:

```ruby
field :name, String, null: true # String
field :id, ID, null: false # ID!
field :scores, [Integer], null: false # [Int!]!
field :teammates, [Types::User], null: false  do # [User!]!
  argument :teamName, String, required: true # String!
  argument :name, String, required: false # String
end
```

### Connection fields & types

There is no `connection(...)` method. Instead, connection fields are inferred from the type name.

If the type name ends in `Connection`, the field is treated as a connection field.

This default may be overridden by passing a `connection: true` or `connection: false` keyword.

For example:

```ruby
# This will be treated as a connection, since the type name ends in "Connection"
field :projects, Types::ProjectType.connection_type
```

### Resolve function compatibility

If you define a type with a class, you can use existing GraphQL-Ruby resolve functions with that class, for example:

```ruby
# Using a Proc literal or #call-able
field :something, ... resolve: ->(obj, args, ctx) { ... }
# Using a predefined field
field :do_something, field: Mutations::DoSomething.field
# Using a GraphQL::Function
field :something, function: Functions::Something.new
```

When using these resolution implementations, they will be called with the same `(obj, args, ctx)` parameters as before.

### Resolution with methods

If you implement a field by defining a method, you should expect some automatic transformations:

- GraphQL arguments will be converted to Ruby keyword arguments.
- method names should be `underscore_cased`.
- argument names will be passed to the method as `underscore_cased` Ruby keyword args.

Inside the method, you can access some instance variables:

- `@context` is the query context (formerly `ctx` to resolve functions)
- `@object` is the underlying application object (formerly `obj` to resolve functions)

For example:

```ruby
# type TodoList {
#   items(isCompleted: Boolean): [TodoItem]!
# }
class Types::TodoList < Types::BaseObject
  field :items, [Types::TodoItem], null: false do
    argument :is_completed, Boolean, required: false
  end

  # GraphQL arg converted to Ruby kwarg:
  def items(is_completed: nil)
    # @context is the query context
    current_user = @context[:current_user]
    # @object is the underlying TodoList
    if current_user != @object.owner
      # not authorized:
      []
    elsif is_completed.nil?
      @object.items
    else
      @object.items.where(completed: is_completed)
    end
  end
end
```

### Implementing interfaces

If an object implements any interfaces, they can be added with `implements`, for example:

```ruby
# This object implements some interfaces:
implements GraphQL::Relay::Node.interface, Types::UserAssignableType
```

See below for how interfaces are "inherited" by object classes.

## Interface classes

Interfaces extend `GraphQL::Schema::Interface`. First, make a base class:

```ruby
class BaseInterface < GraphQL::Schema::Interface
  # optional, see below for customizing field definitions
  field_class MyCustomField
end
```

Then, extend that for each interface:

```ruby
class RetailItemType < BaseInterface
  description "Something that can be bought"
  field :price, PriceType, "How much this item costs", null: false

  # Optional: if this method is defined, it overrides `Schema.resolve_type`
  def self.resolve_type(object, context)
    context.schema.types[object.class.name]
  end

  module Implementation
    # optional, see below
  end
end
```

Interface classes are never instantiated. At runtime, only their `.resolve_type` methods are called (if they're defined).

### Implementation modules

An interface may contain a module named `Implementation`. If it does, that module will be included into any `Object` class which implements the interface. For example, this `Implementation` module contains the `#price` method:

```ruby
class RetailItemType < BaseInterface
  field :price, PriceType, null: false

  module Implementation
    def price
      Price.new(price_in_cents)
    end
  end
end
```

When the interface is implemented by an `Object`:

```ruby
class CarType < BaseObject
  implements RetailItemType
end
```

Then the object gets a few things from the interface:

- Any `field` definitions from the interface (which may be overridden by the `Object`)
- The `Implementation` module is `include`-d into the object, so it gets any methods from that module (which may be overridden by the `Object`)

Specifically, in the example above, `CarType` would get a field named `price` and a `#price` method which implements that field.

## Union classes

Unions extend `GraphQL::Schema::Union`. First, make a base class:

```ruby
class BaseUnion < GraphQL::Schema::Union
end
```

Then, extend that one for each union in your schema:

```ruby
class CommentSubjectType < BaseUnion
  description "Objects which may be commented on"
  possible_types PostType, ImageType

  # Optional: if this method is defined, it will override `Schema.resolve_type`
  def self.resolve_type(object, context)
    if object.is_a?(BlogPost)
      PostType
    else
      ImageType
    end
  end
end
```

Union classes are never instantiated; At runtime, only their `.resolve_type` methods may be called (if defined).

## Enum classes

Enums extend `GraphQL::Schema::Enum`. First, make a base class:

```ruby
class BaseEnum < GraphQL::Schema::Enum
end
```

Then, extend that class to define enums:

```ruby
class CategoryType < BaseEnum
  description "Things that a blog post can be about"
  value "SPORTS", "Various sports ball things"
  value "SOFTWARE", "Programming and stuff", value: "CODING"
end
```

The `value(...)` API is identical to the previous API.

Enum classes are never instantiated and their methods are never called.


## Input object classes

Input objects extend `GraphQL::Schema::InputObject`. First, make a base class:

```ruby
class BaseInputObject < GraphQL::Schema::InputObject
end
```

Then extend it for your input objects:

```ruby
class PostInputType < BaseInputObject
  argument :title, String, required: true
  argument :body, String, required: true
  argument :is_draft, Boolean, required: false, default_value: false
end
```

`argument` defines input fields on the input object. The signature is:

```ruby
argument(name, type, description = nil, required:, default_value: nil)
```

### Using input objects

For fields on class-based objects, inputs are provided as Ruby keyword arguments. The value is an instance of the `InputObject` class, for example:

```ruby
class MutationType < BaseObject
  field :createPost, PostType, null: false do
    argument :post_input, PostInputType, required: true
  end

  def create_post(post_input:)
    post_input # => #<PostInputType ...>
    # ...
  end
end
```

For legacy-style fields, a `GraphQL::Query::Arguments` instance is provided as `args` (just like the previous behavior).

### Accessing argument values

Given an instance of `GraphQL::Schema::InputObject`, you can access its values in a few ways:

- __method calls__: each argument is accessible by an underscore-cased method, eg `argument :isDraft` becomes `#is_draft`
- __key lookup__: as String or Symbol, in camel-case, for example, `argument :isDraft` is accessible as `input["isDraft"]` or `input[:isDraft]` (this matches previous behavior)

### Initialization, methods and instance variables

Input objects are initialized with the provided user input. They have two instance variables by default:

- `@arguments`: A `GraphQL::Query::Arguments` instance (the value of `args` in `(obj, args, ctx)->{...}`)
- `@context`: The current `GraphQL::Query::Context`

Since input objects are passed into resolve methods, you can also define helper methods in them which can be called by resolve methods. For example, define a helper on the input object:

```ruby
class PostInputType < BaseInputObject
  # ...
  def total_length
    title.length + body.length
  end

  def allowed_length
    @context[:current_user]&.admin? ? Float::INFINITY : 5000
  end
end
```

Then, call the helper methods in your resolve method:

```ruby
def create_post(post_input:)
  if post_input.total_length < post_input.allowed_length
    # ... create new Post
  else
    # return validation errors
  end
end
```

This example is not very practical, but it shows how `prepare:` functions can be re-applied. (They can also be applied in `#initialize`).

## Scalar classes

Custom scalars extend `GraphQL::Schema::Scalar`. First, make a base class:

```ruby
class BaseScalar < GraphQL::Schema::Scalar
end
```

Then extend it for your custom scalars:

```ruby
class HTMLType < BaseScalar
  description "A string containing valid HTML"
  def self.coerce_input(value, context)
    HTMLValidator.validate!(value)
    value
  end

  def self.coerce_result(value, context)
    value # just return the String as-is
  end
end
```

Scalars are never initialized; only their `.coerce_*` methods are called at runtime.

## Customizing definitions

The new API provides alternatives to `accepts_definitions`.

### Customizing type definitions

In your custom classes, you can override `.to_graphql` to customize the type that will be used at runtime. For example, to assign metadata values to an ObjectType:

```ruby
class BaseObject < GraphQL::Schema::Object
  # Call this method in an Object class to set the permission level:
  def self.required_permission(permission_level)
    @required_permission = permission_level
  end

  # This method is overridden to customize object types:
  def self.to_graphql
    type_defn = super # returns a GraphQL::ObjectType
    # Get a configured value and assign it to metadata
    type_defn.metadata[:required_permission] = @required_permission
    type_defn
  end
end

# Then, in concrete classes
class Dossier < BaseObject
  # The Dossier object type will have `.metadata[:required_permission] # => :admin`
  permission_level :admin
end
```

Now, any runtime code which uses `.metadata[:required_permission]` will get the right value.

### Customizing fields

Fields are generated in a different way. Instead of using classes, they are generated with instances of `GraphQL::Schema::Field` (or a subclass). In short, the definition process works like this:

```ruby
# This is what happens under the hood, roughly:
# In an object class:
field :name, String, null: false
# ...
# Leads to:
field_config = GraphQL::Schema::Field.new(:name, String, null: false)
# Then, later:
field_config.to_graphql # => returns a GraphQL::Field instance
```

So, you can customize this process by:

- creating a custom class which extends `GraphQL::Schema::Field`
- overriding `#initialize` and `#to_graphql` on that class (instance methods)
- registering that class as the `field_class` on Objects and Interfaces which should use the customized field.

For example, you can create a custom class which accepts a new parameter to `initialize`:

```ruby
class AuthorizedField < GraphQL::Schema::Field
  # Override #initialize to take a new argument:
  def initialize(*args, required_permission:, **kwargs, &block)
    @required_permission = required_permission
    # Pass on the default args:
    super(*args, **kwargs, &block)
  end

  def to_graphql
    field_defn = super # Returns a GraphQL::Field
    field_defn.metadata[:required_permission] = @required_permission
    field_defn
  end
end
```

Then, pass the field class as `field_class(...)` wherever it should be used:

```ruby
class BaseObject < GraphQL::Schema::Object
  # Use this class for defining fields
  field_class AuthorizedField
end

# And/Or
class BaseInterface < GraphQL::Schema::Interface
  field_class AuthorizedField
end
```

Now, `AuthorizedField.new(*args, &block).to_graphql` will be used to create `GraphQL::Field`s.

### Customizing Arguments

Arguments may be customized in a similar way to Fields.

- Create a new class extending `GraphQL::Schema::Argument`
- Assign it to your field class with `argument_class(MyArgClass)`

Then, in your custom argument class, you can use:

- `#initialize(name, type, desc = nil, **kwargs)` to take input from the DSL
- `#to_graphql` to modify the conversion to a {{ "GraphQL::Argument" | api_doc }}

### Customization compatibility

Inevitably, this will result in some duplication while you migrate from one definition API to the other. Here are a couple of ways to re-use _old_ customizations with the new framework:

__Invoke `.call` directly__. If you defined a module with a `.call` method, you can invoke that method during `.to_graphql`. For example:

```ruby
class BaseObject < GraphQL::Schema::Object
  def self.to_graphql
    type_defn = super
    # Re-use the accepts_definition callback manually:
    DefinePermission.call(type_defn, required_permission: @required_permission)
    type_defn
  end
end
```

__Use `.redefine`__. You can re-open a `.define` block at any time with `.redefine`. It returns a new, updated instance based on the old one. For example:

```ruby
class BaseObject < GraphQL::Schema::Object
  def self.to_graphql
    type_defn = super
    # Read the value from the instance variable, since ivars don't work in `.define {...}` blocks
    configured_permission = @required_permission

    updated_type_defn = type_defn.redefine do
      # Use the accepts_definition method:
      required_permission(configured_permission)
    end

    # return the updated definition
    updated_type_defn
  end
end
```
