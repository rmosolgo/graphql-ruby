---
layout: guide
doc_stub: false
search: true
section: Schema
title: Extending the DSL
desc: Customize the DSL for your application
index: 6
---

You can extend GraphQL's domain-specific language (DSL) for your own usage.

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
