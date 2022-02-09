---
layout: guide
doc_stub: false
search: true
enterprise: true
section: GraphQL Enterprise - Changesets
title: Defining Changesets
desc: Creating a set of modifications to release in an API version
index: 2
---

After {% internal_link "installing Changeset integrations", "/changesets/installation" %} in your schema, you can create Changesets which modify parts of the schema. Changesets extend `GraphQL::Enterprise::Changeset` and include a `release` and some `modifies ...` configurations.

For example, this Changeset marks the old `Recipe.flag` field as deprecated:

```ruby
# app/graphql/changesets/deprecate_recipe_flag.rb
class Changesets::DeprecateRecipeFlag < GraphQL::Enterprise::Changeset
  release "2020-12-01"
  modifies Types::Recipe do
    field :flag, Types::RecipeFlag, null: false, deprecation_reason: "Recipes now have multiple flags, use `flags` instead."
  end
end
```

  Then this Changeset removes `Recipe.flag` entirely:

```ruby
# app/graphql/changesets/remove_recipe_flag.rb
class Changesets::RemoveRecipeFlag < GraphQL::Enterprise::Changeset
  release "2021-03-01"
  modifies Types::Recipe do
    remove_field :flag
  end
end
```

Additionally, the Changesets must be added to the schema (see the {% internal_link "Releases guide", "/changesets/releases" %}):

```ruby
class MyAppSchema < GraphQL::Schema
  # ...
  use GraphQL::Enterprise::Changeset::Release, changesets: [
    Changesets::DeprecateRecipeFlag,
    Changesets::RemoveRecipeFlag,
  ]
end
```

Although the changesets above have one modification each, a changeset may have any number of modifications in it.

See below for the different kind of modifications you can make in a changeset:

- [Fields](#fields): adding, modifying, and removing fields
- [Arguments](#arguments): adding, modifying, and removing arguments
- [Enum values](#enum-values): adding, modifying, and removing arguments
- [Unions](#unions): adding or removing object types from a union
- [Interfaces](#interfaces): adding or removing interface implementations from object types
- [Types](#types): changing one type definition for another
- [Runtime](#runtime): choosing a behavior at runtime based on the current request and changeset

## Fields

In a Changeset, you can add, redefine, or remove fields that belong to object types, interface types, or resolvers. First, use `modifies ... do ... end`, naming the owner of the field:

```ruby
class Changesets::RecipeMigration < GraphQL::Enterprise::Changeset
  modifies Types::Recipe do
    # modify `Recipe`'s fields here
  end
end
```

Then...

- To add or redefine a field, use `field(...)`, including the same configurations you'd use in a type definition (see {{ "GraphQL::Schema::Field#initialize" | api_doc }}). The definition given here will override the previous definition (if there was one) whenever this Changeset applies.
- To remove a field, use `remove_field(field_name)`, where `field_name` is the name given to `field(...)` (usually an underscore-cased symbol)

When a field is removed, queries that request that field will be invalid, unless the client has requested a previous API version where the field is still available.

## Arguments

In a Changeset, you can add, redefine, or remove arguments that belong to fields, input objects, or resolvers. Use `modifies` to select the argument owner, for example:

```ruby
class Changesets::FilterMigration < GraphQL::Enterprise::Changeset
  modifies Types::IngredientsFilter do
    # modify input object arguments here
  end
  # ...
```

When versioning field arguments, use a second `modifies(field_name) { ... }` call to select the field to modify:

```ruby
  # ...
  modifies Types::Query do
    modifies :ingredients do
      # modify the arguments of `Query.ingredients(...)` here
    end
  end
end
```

Then...

- To add or redefine an argument, use `argument(...)`, passing the same configurations you'd usually pass to `argument(...)` (see {{ "GraphQL::Schema::Argument#initialize" | api_doc }}). The redefined argument will override any previous definitions whenever this Changeset is active.
- To remove an argument, use `remove_argument(argument_name)`, where `argument_name` is the name given to `field(...)` (usually an underscore-cased symbol)

When arguments are removed, the schema will reject any queries which use them unless the client has requested a previous API version where the argument is still allowed.

## Enum Values

In a Changeset, you can add, redefine, or remove enum values. First, use `modifies ... do ... end`, naming the enum type:

```ruby
class Changesets::RecipeFlagMigration < GraphQL::Enterprise::Changeset
  modifies Types::RecipeFlag do
    # Modify `RecipeFlag`'s values here
  end
end
```

Then...

- To add a value, use `value(...)`, passing the same configurations you'd usually pass to `value(...)` in an enum type (see {{ "GraphQL::Schema::Enum.value" | api_doc }}). The configuration given here will override previous configurations whenever this Changeset applies.
- To remove a value, use `remove_value(name)`, where `name` is the name given to `value(...)` (an all-caps string)

When enum values are removed, they won't be accepted as input and they won't be allowed as return values from fields unless the client has requested a previous API version where those values are still allowed.

## Unions

In a Changeset, you can add to or remove from a union's possible types. First, use `modifies ...`, naming the union type:

```ruby
class Changesets::MigrateLegacyCookingTechniques < GraphQL::Enterprise::Changeset
  modifies Types::CookingTechnique do
    # change the possible_types of the `CookingTechnique` union here
  end
end
```

Then...

- To add one or more possible types, use `possible_types(*object_types)`, passing one or more object type classes. The given types will be _added_ to the union's set of possible types whenever this Changeset is active.
- To remove one or more more possible types, use `remove_possible_types(*object_types)`, passing one or more object type classes

When a possible type is removed, it will not be associated with the union type in introspection queries or schema dumps.

## Interfaces

In a Changeset, you can add to or remove from an object type's interface definitions. First, use `modifies ...`, naming the object type:

```ruby
class Changesets::ModifyImplements < GraphQL::Enterprise::Changeset
  modifies Types::Ingredient do
    # change `Ingredient`'s interface implementations here
  end
end
```

Then...

- To add one or more interface implementations, use `implements(*interface_types)`, passing one or more interface type modules. This will add the interface and its fields to the object whenever this Changeset is active.
- To remove one or more more interface implementations, use `remove_implements(*interface_types)`, passing one or more interface type modules

When an interface implementation is removed, then the interface will not be associated with the object in introspection queries or schema dumps. Also, any fields inherited from the interface will be hidden from clients. (If the object defines the field itself, it will still be visible.)

## Types

Using Changesets, it's possible to define a new type using the same name as an old type. (Only one type per name is allowed for each query, but different queries can use different types for the same name.)

First, to define two types with the same name, make two different type definitions. One of them will have to use `graphql_name(...)` to specify the conflicting type name. For example, to migrate an enum type to an object type, define two types:

```ruby
# app/graphql/types/legacy_recipe_flag.rb

# In the old version of the schema, "recipe flags" were limited to defined set of values.
# This enum was renamed from `Types::RecipeFlag`, then `graphql_name("RecipeFlag")`
# was added for GraphQL.
class Types::LegacyRecipeFlag < Types::BaseEnum
  graphql_name "RecipeFlag"
  # ...
end
```

```ruby
# app/graphql/types/recipe_flag.rb

# But in the new schema, each flag is a full-fledge object with fields of its own
class Types::RecipeFlag < Types::BaseObject
  field :name, String, null: false
  field :is_vegetarian, Boolean, null: false
  # ...
end
```

Then, add or update fields or arguments to use the _new_ type instead of the old one. For example:

```ruby
class Changesets::MigrateRecipeFlagToObject < GraphQL::Enterprise::Changeset
  modifies Types::Recipe do
    # in types/recipe.rb, this is defined with `field :flags, [Types::LegacyRecipeFlag]`
    # Here, update the field to use the _object_ instead:
    update_field :flags, [Types::RecipeFlag]
  end
end
```

With that Changeset, `Recipe.flags` will return an object type instead of an enum type. Clients requesting older versions will still receive enum values from that field.

The resolver will probably need an update, too, for example:

```ruby
class Types::Recipe < Types::BaseObject
  # Here's the original definition, which is modified by `MigrateRecipeFlagToObject`:
  field :flags, [Types::LegacyRecipeFlag], null: false

  def flags
    all_flag_objects = object.flag_objects
    if Changesets::MigrateRecipeFlagToObject.active?(context)
      all_flag_objects
    else
      # Convert this to enum values, for legacy behavior:
      all_flag_objects.map { |f| f.name.upcase }
    end
  end
end
```

That way, legacy clients will continue to receive enum values while new clients will receive objects.

## Runtime

While a query is running, you can check if a changeset applies by using its `.active?(context)` method. For example:

```ruby
class Types::Recipe
  field :flag, Types::RecipeFlag, null: true

  def flag
    # Check if this changeset applies to the current request:
    if Changesets::DeprecateRecipeFlag.active?(context)
      Stats.count(:deprecated_recipe_flag, context[:viewer])
    end
    # ...
  end
end
```

Besides observability, you can use a runtime check when a resolver needs to pick a different behavior depending on the API version.

After defining a changeset, add it to the schema to {% internal_link "release it", "/changesets/releases" %}.
