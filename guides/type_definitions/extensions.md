---
layout: guide
doc_stub: false
search: true
section: Type Definitions
title: Extending the GraphQL-Ruby Type Definition System
desc: Adding metadata and custom helpers to the DSL
index: 8
class_based_api: true
redirect_from:
  - /schema/extending_the_dsl/
---

While integrating GraphQL into your app, you can customize the definition DSL. For example, you might:

- Assign "area of responsibility" to different types and fields
- DRY up shared logic between types and fields
- Attach metadata for use during authorization

This guide describes various options for extending the class-based definition API. Keep in mind that these approaches may change as the API matures. If you're having trouble, consider opening an issue on GitHub to get help.

## Customization Overview

In general, the schema definition process goes like this:

- The application defines lots of classes for the GraphQL types
- The first time the schema is used, it "boots"...
- Which involves calling `.to_graphql` on all the application-defined classes
  - `.to_graphql` returns a "legacy" GraphQL object (eg, `GraphQL::ObjectType`, `GraphQL::ScalarType`)
- Non-type objects (fields, arguments, enum values) have a slightly different process:
  - During a type's `.to_graphql` method, definition objects are initialized (eg `GraphQL::Schema::Field.new(...)`)
  - Then, the initialized object receives `.to_graphql` (eg {{ "GraphQL::Schema::Field#to_graphql" | api_doc }})
  - `.to_graphql` a "legacy" GraphQL object (eg `GraphQL::Field`)

This process will certainly change over time. The goal to entirely remove "legacy" GraphQL objects from the system. So, at that time, `.to_graphql` will no longer be used.

Another important note: after GraphQL-Ruby converts a class to a "legacy" object, the "legacy" object may be accessed using `.graphql_definition`. This cached instance is the "one true instance" used by GraphQL-Ruby.

## Customizing type definitions

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
  required_permission :admin
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

### Customizing Enum Values

Enum values may be customized in a similar way to Fields.

- Create a new class extending `GraphQL::Schema::EnumValue`
- Assign it to your base `Enum` class with `enum_value_class(MyEnumValueClass)`

Then, in your custom argument class, you can use:

- `#initialize(name, desc = nil, **kwargs)` to take input from the DSL
- `#to_graphql` to modify the conversion to a {{ "GraphQL::EnumType::EnumValue" | api_doc }}

### Customization compatibility

Inevitably, this will result in some duplication while you migrate from one definition API to the other. Here are a couple of ways to re-use _old_ customizations with the new framework:

__Pass-through with `accepts_definition`__. New schema classes have an `accepts_definition` method. They set up a configuration method which will pass the provided value to the existing (legacy-style) configuration function, for example:

```ruby
# Given a legacy-style configuration function:
GraphQL::ObjectType.accepts_definitions({ permission_level: ->(...) { ... } })

# Prepare the config method in the base class:
class BaseObject < GraphQL::Schema::Object
  accepts_definition :permission_level
end

# Call the config method in the object class:
class Account < BaseObject
  permission_level 1
end

# Then, the runtime object will have the configured value, for example:
MySchema.find("Account").metadata[:permission_level]
# => 1
```

See {{ "GraphQL::Schema::Member::AcceptsDefinition" | api_doc }} for the implementation.

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
