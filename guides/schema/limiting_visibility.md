---
title: Schema — Limiting Visibility
---

Sometimes, you want to hide schema elements from some users. For example:

- some elements are feature flagged; or
- some elements require higher permissions

If you only want to limit _access_ to these fields, consider the options described in the [authorization guide]({{site.baseurl}}/queries/authorization).

If you want to _completely hide_ some fields, types, enum values or arguments, read on!

## Masking

You can hide parts of the schema by passing `except:` to `Schema.execute`. For example:

```ruby
mask = PermissionMask.new(@current_user)
MySchema.execute(query_string, except: mask)
```

During that query, some elements will be hidden. This means that fields, types, arguments or enum values will be treated as if they were not defined at all.

A mask must respond to `#call(schema_member)`. When that methods returns truthy, the schema member will be hidden.

For example, here's an implementation of `PermissionMask` above:

```ruby
class PermissionMask
  def initialize(person)
    @person = person
  end

  # If this returns true, the schema member will be hidden
  def call(schema_member)
    Permissions.hidden?(person, schema_member)
  end
end
```

The `schema_member` may be any of:

- Type ({{ "GraphQL::BaseType" | api_doc }} and subclasses)
- Field ({{ "GraphQL::Field" | api_doc }})
- Argument ({{ "GraphQL::Argument" }} | api_doc }})
- Enum value ({{ "GraphQL::EnumType::EnumValue" | api_doc }})

The result of `#call(schema_member)` is __cached__ during the query.

## Use with Metadata

This feature pairs nicely with attaching custom data to types. See the [types and fields guide]({{ site.baseurl }}/schema/types_and_fields) for information about assigning values to an object's `metadata`.

Then, you can check `metadata` in your mask. For example, to hide fields based on a metadata flag:

```ruby
# Hide secret objects from this user
top_secret = ->(schema_member) { schema_member.metadata[:top_secret]}
MySchema.execute(query_string, except: top_secret)
```
