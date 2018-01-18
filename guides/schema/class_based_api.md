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
- [Using the upgrader](#upgrader)
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
- [Custom introspection](#custom-introspection)


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
  - By default, list members are _non-null_, for example, `[Types::UserType]` becomes `[User!]`
  - If your list members may be null, add `, null: true` to the array: `[Types::UserType, null: true]` becomes `[User]` (the list may include `nil`)
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

## Upgrader

`1.8` includes an _auto-upgrader_ for transforming Ruby files from the `.define`-based syntax to `class`-based syntax. The upgrader is a pipeline of sequential transform operations. It ships with default pipelines, but you may customize the upgrade process by replacing the built-in pipelines with a custom ones.

The upgrader has an additional dependency, `parser`, which you must add to your project manually (for example, by adding to your `Gemfile`).

Remember that your project may be transformed one file at a time because the two syntaxes are compatible. This way, you can convert a few files and run your tests to identify outstanding issues, and continue working incrementally.

This transformation may not be perfect, but it should cover the most common cases. If you want to ask a question or report a bug, please {% open_an_issue "Upgrader question/bug report","Please share: the source code you're trying to transform, the output you got from the transformer, and the output you want to get from the transformer." %}.

### Using the Default Upgrade Task

The upgrader ships with rake tasks, included as a railtie ([source](https://github.com/rmosolgo/graphql-ruby/blob/1.8-dev/lib/graphql/railtie.rb)). The railtie will be automatically installed by your Rails app, and it provides the following tasks:

- `graphql:upgrade:schema[path/to/schema.rb]`: upgrade the Schema file
- `graphql:upgrade:member[path/to/some/type.rb]`: upgrade a type definition (object, interface, union, etc)
- `graphql:upgrade[app/graphql/**/*]`: run the `member` upgrade on files which have a suffix of `_(type|interface|enum|union).rb`
- `graphql:upgrade:create_base_objects[path/to/graphql/]`: add base classes to your project

### Writing a Custom Upgrade Task

You might write a custom task because:

- You want to customize the transformation pipeline
- You're not using Rails, so a railtie won't work

To write a custom task, you can write a rake task (or Ruby script) which uses the upgrader's API directly.

Here's the code to upgrade a type definition with the default transform pipeline:

```ruby
# Read the original source code into a string
original_source = File.read("path/to/type.rb")
# Initialize an upgrader with the default transforms
upgrader = GraphQL::Upgrader::Member.new(original_source)
# Perform the transformation, get the transformed source code
transformed_source = upgrader.upgrade
# Update the source file with the new code
File.write("path/to/type.rb", transformed_source)
```

In this custom code, you can pass some keywords to {{ "GraphQL::Upgrader::Member.new" | api_doc }}:

- `type_transforms:` Applied to the source code as a whole, applied first
- `field_transforms:` Applied to each field/connection/argument definition (extracted from the source, transformed independently, then re-inserted)
- `clean_up_transforms:` Applied to the source code as a whole, _after_ the type and field transforms

Keep in mind that these transforms are performed in sequence, so the text changes over time. If you want to transform the source text, use `.unshift()` to add transforms to the _beginning_ of the pipeline instead of the end.

For example, in `script/graphql-upgrade`:

```ruby
#!/usr/bin/env ruby

# @example Upgrade app/graphql/types/user_type.rb:
#  script/graphql-upgrade app/graphql/types/user_type.rb

# Replace the default define-to-class transform with a custom one:
type_transforms = GraphQL::Upgrader::Member::DEFAULT_TYPE_TRANSFORMS.map { |t|
  if t == GraphQL::Upgrader::TypeDefineToClassTransform
    GraphQL::Upgrader::TypeDefineToClassTransform.new(base_class_pattern: "Platform::\\2s::Base")
  else
    t
  end
}

# Add this transformer at the beginning of the list:
type_transforms.unshift(GraphQL::Upgrader::ConfigurationToKwargTransform.new(kwarg: "visibility"))

# run the upgrader
original_text = File.read(ARGV[0])
upgrader = GraphQL::Upgrader::Member.new(original_text, type_transforms: type_transforms)
transformed_text = upgrader.upgrade
File.write(filename, transformed_text)
```

### Writing a custom transformer

Objects in the transform pipeline may be:

- A class which responds to `.new.apply(input_text)` and returns the transformed code
- An object which responds to `.apply(input_text)` and returns the transformed code

The library provides a {{ "GraphQL::Upgrader::Transform" | api_doc }} base class with a few convenience methods. You can also customize the built-in transformers listed below.

For example, here's a transform which rewrites type definitions from a `model_type(model) do ... end` factory method to the class-based syntax:

```ruby
# Create a custom transform for our `model_type` factory:
class ModelTypeToClassTransform < GraphQL::Upgrader::Transform
  def initialize
    # Find calls to the factory method, which have a type class inside
    @find_pattern = /^( +)([a-zA-Z_0-9:]*) = model_type\(-> ?\{ ?:{0,2}([a-zA-Z_0-9:]*) ?\} ?\) do/
    # Replace them with a class definition and a `model_name("...")` call:
    @replace_pattern = "\\1class \\2 < Platform::Objects::Base\n\\1  model_name \"\\3\""
  end

  def apply(input_text)
    # Run the substitution on the input text:
    input_text.sub(@find_pattern, @replace_pattern)
  end
end
# Add the class to the beginning of the pipeline
type_transforms.unshift(ModelTypeToClassTransform)
```

### Built-in transformers

Follow links to the API doc to read the source of each transform:

Type transforms ({{ "GraphQL::Upgrader::Member::DEFAULT_TYPE_TRANSFORMS" | api_doc }}):

- {{ "GraphQL::Upgrader::Transform" | api_doc }} base class, provides a `normalize_type_expression` helper
- {{ "GraphQL::Upgrader::TypeDefineToClassTransform" | api_doc }} turns `.define` into `class ...` with a regexp substitution
- {{ "GraphQL::Upgrader::NameTransform" | api_doc }} takes `name "..."` and removes it if it's redundant, or converts it to `graphql_name "..."`
- {{ "GraphQL::Upgrader::InterfacesToImplementsTransform" | api_doc }} turns `interfaces [A, B...]` into `implements(A)\nimplements(B)...`

Field transforms ({{ "GraphQL::Upgrader::Member::DEFAULT_FIELD_TRANSFORMS" | api_doc }}):

- {{ "GraphQL::Upgrader::RemoveNewlinesTransform" | api_doc }} removes newlines from field definitions to normalize them
- {{ "GraphQL::Upgrader::PositionalTypeArgTransform" | api_doc }} moves `type X` from the `do ... end` block into a positional argument, to normalize the definition
- {{ "GraphQL::Upgrader::ConfigurationToKwargTransform" | api_doc }} moves a `do ... end` configuration to a keyword argument. By default, this is used for `property` and `description`. You can add new instances of this transform to convert your custom DSL.
- {{ "GraphQL::Upgrader::PropertyToMethodTransform" | api_doc }} turns `property:` to `method:`
- {{ "GraphQL::Upgrader::UnderscoreizeFieldNameTransform" | api_doc }} converts field names to underscore-case. __NOTE__ that this conversion may be _wrong_ in the case of `bodyHTML => body_html`. When you find it is wrong, manually revert it and preserve the camel-case field name.
- {{ "GraphQL::Upgrader::ResolveProcToMethodTransform" | api_doc }} converts `resolve -> { ... }` to `def {field_name} ... ` method definitions
- {{ "GraphQL::Upgrader::UpdateMethodSignatureTransform" | api_doc }} converts the type name to the new syntax, and adds `null:`/`required:` to the method signature

Clean-up transforms ({{ "GraphQL::Upgrader::Member::DEFAULT_CLEAN_UP_TRANSFORMS" | api_doc }}):

- {{ "GraphQL::Upgrader::RemoveExcessWhitespaceTransform" | api_doc }} removes redundant newlines
- {{ "GraphQL::Upgrader::RemoveEmptyBlocksTransform" | api_doc }} removes `do end` with nothing inside them

## Roadmap

Here is a working plan for rolling out this feature:

- ongoing:
  - ☐ Receive feedback from GraphQL schema owners about the new API (usability & goals)
- graphql 1.8:
  - ☑ Build a schema definition API based on classes instead of singletons
  - ☑ Migrate a few components of GitHub's GraphQL schema to this new API
  - ☐ Build advanced class-based features:
    - ☑ Custom `Context` classes
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

### Customizing `@context`

The `@context` object passed through each query may be customized by creating a subclass of {{ "GraphQL::Query::Context" | api_doc }} and passing it to `context_class` in your schema class:

```ruby
class MyContext < GraphQL::Query::Context
  # short-hand access to a value:
  def current_user
    self[:current_user]
  end
end

# then:
class MySchema < GraphQL::Schema
  # ...
  context_class MyContext
end
```

Then, during queries, `@context` will be an instance of `MyContext`.

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

## Custom Introspection

With a class-based schema, you can use custom introspection types.

```ruby
# create a module namespace for your custom types:
module Introspection
  # described below ...
end

class MySchema < GraphQL::Schema
  # ...
  # then pass the module as `introspection`
  introspection Introspection
end
```

Keep in mind that off-the-shelf tooling may not support your custom introspection fields. You may have to modify existing tooling or create your own tools to make use of your extensions.

### Introspection Namespace

The introspection namespace may contain a few different customizations:

- Class-based type definitions which replace the built-in introspection types (such as `__Schema` and `__Type`)
- `EntryPoints`, A class-based type definition containing introspection entry points (like `__schema` and `__type(name:)`).
- `DynamicFields`, A class-based type definition containing dynamic, globally-available fields (like `__typename`.)

### Custom Introspection Types

The `module` passed as `introspection` may contain classes with the following names, which replace the built-in introspection types:

Custom class name | GraphQL type | Built-in class name
--|--|--
`SchemaType` | `__Schema` | `GraphQL::Introspection::SchemaType`
`TypeType` | `__Type` | `GraphQL::Introspection::TypeType`
`DirectiveType` | `__Directive` | `GraphQL::Introspection::DirectiveType`
`DirectiveLocationType` | `__DirectiveLocation` | `GraphQL::Introspection::DirectiveLocationEnum`
`EnumValueType` | `__EnumValue` | `GraphQL::Introspection::EnumValueType`
`FieldType` | `__Field` | `GraphQL::Introspection::FieldType`
`InputValueType` | `__InputValue` | `GraphQL::Introspection::InputValueType`
`TypeKindType` | `__TypeKind` | `GraphQL::Introspection::TypeKindEnum`

The class-based definitions' names _must_ match the names of the types they replace.

#### Extending a Built-in Type

The built-in classes listed above may be extended:

```ruby
module Introspection
  class SchemaType < GraphQL::Introspection::SchemaType
    # ...
  end
end
```

Inside the class definition, you may:

- add new fields by calling `field(...)` and providing implementations
- redefine field structure by calling `field(...)`
- provide new field implementations by defining methods
- provide new descriptions by calling `description(...)`

### Introspection Entry Points

The GraphQL spec describes two entry points to the introspection system:

- `__schema` returns data about the schema (as type `__Schema`)
- `__type(name:)` returns data about a type, if one is found by name (as type `__Type`)

You can re-implement these fields or create new ones by creating a custom `EntryPoints` class in your introspection namespace:

```ruby
module Introspection
  class EntryPoints < GraphQL::Introspection::EntryPoints
    # ...
  end
end
```

This class an object type definition, so you can override fields or add new ones here. They'll be available on the root `query` object, but ignored in introspection (just like `__schema` and `__type`).

### Dynamic Fields

The GraphQL spec describes a field which may be added to _any_ selection: `__typename`. It returns the name of the current GraphQL type.

You can add fields like this (or override `__typename`) by creating a custom `DynmaicFields` defintion:

```ruby
module Introspection
  class DynamicFields < GraphQL::Introspection::DynamicFields
    # ...
  end
end
```

Any fields defined there will be available in any selection, but ignored in introspection (just like `__typename`).
