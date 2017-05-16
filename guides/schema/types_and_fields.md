---
layout: guide
search: true
title: Schema — Types and Fields
---

Types, fields and arguments make up a schema's type system. These objects are also open to extension via `metadata` and `accepts_definitions`.

### Referencing Types

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

## Extending type and field definitions

Types, fields, and arguments have a `metadata` hash which accepts values during definition.

First, make a custom definition:

```ruby
GraphQL::ObjectType.accepts_definitions resolves_to_class_names: GraphQL::Define.assign_metadata_key(:resolves_to_class_names)
# or:
# GraphQL::Field.accepts_definitions(...)
# GraphQL::Argument.accepts_definitions(...)

MySchema = GraphQL::Schema.define do
  # ...
end
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
  resolve_type ->(obj, ctx) {
    class_name = obj.class.name
    MySchema.types.values.find { |type| type.metadata[:resolves_to_class_names].include?(class_name) }
  }
end
```

This behavior is provided by {{ "GraphQL::Define::InstanceDefinable" | api_doc }}.
