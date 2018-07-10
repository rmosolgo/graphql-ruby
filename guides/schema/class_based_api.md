---
layout: guide
doc_stub: false
search: true
section: Schema
title: Class-based API
desc: Define your GraphQL schema with Ruby classes (1.8.x alpha releases)
class_based_api: true
index: 10
---

In GraphQL `1.8`+, you can use Ruby classes to build your schema. You can __mix__ class-style and `.define`-style type definitions in a schema.

You can get an overview of this new feature:

- [Rationale & Goals](#rationale--goals)
- [Compatibility & Migration Overview](#compatibility--migration-overview)
- [Using the upgrader](#upgrader)
- [Roadmap](#roadmap)

And learn about the APIs:

- {% internal_link "Schema class", "/schema/definition" %}
- [Common type configurations](#common-type-configurations) (shared by all the following types)
- {% internal_link "Object classes", "/type_definitions/objects" %}
- {% internal_link "Interface classes", "/type_definitions/interfaces" %}
- {% internal_link "Union classes", "/type_definitions/unions" %}
- {% internal_link "Enum classes", "/type_definitions/enums" %}
- {% internal_link "Input Object classes", "/type_definitions/input_objects" %}
- {% internal_link "Scalar classes", "/type_definitions/scalars" %}
- {% internal_link "Customizing definitions", "/type_definitions/extensions" %}
- {% internal_link "Custom introspection", "/schema/introspection" %}

## Rationale & Goals

This new API aims to improve the "getting started" experience and the schema customization experience by replacing GraphQL-Ruby-specific DSLs with familiar Ruby semantics (classes and methods).

Additionally, this new API must be cross-compatible with the current schema definition API so that it can be adopted bit-by-bit.

## Compatibility & Migration overview

Parts of your schema can be converted one-by-one, so you can convert definitions gradually.

### Classes

In general, each `.define { ... }` block will be converted to a class.

- Instead of a `GraphQL::{X}Type`, classes inherit from `GraphQL::Schema::{X}`. For example, instead of `GraphQL::ObjectType.define { ... }`, a definition is made by extending `GraphQL::Schema::Object`
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
  - ☑ Build advanced class-based features:
    - ☑ Custom `Context` classes
    - ☑ Custom introspection types
    - ☐ ~~Custom directives~~ Probably will mess with execution soon, not worth the investment now
    - ☐ ~~Custom `Schema#execute` method~~ not necessary
  - ☑ Migrate all of GitHub's GraphQL schema to this new API
- graphql 1.9:
  - ☐ Update all GraphQL-Ruby docs to reflect this new API
- graphql 1.10:
  - ☐ Begin sunsetting `.define`: isolate it in its own module
  - ☐ Remove `.define`

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
