---
layout: guide
doc_stub: false
search: true
title: Limiting Visibility
section: Schema
desc: Flag types and fields so that only some clients can see them.
---

Sometimes, you want to hide schema elements from some users. For example:

- some elements are feature flagged; or
- some elements require higher permissions

If you only want to limit _access_ to these fields, consider using {% internal_link "field instrumentation","/fields/instrumentation" %} to check objects at runtime or {% internal_link "query analyzers","/queries/analysis" %} to check queries before running them.

If you want to _completely hide_ some fields, types, enum values or arguments, read on!

## Filtering

You can hide parts of the schema by passing `except:`  or `only:` to `Schema.execute`. For example:

```ruby
# `except:` blacklists items:
filter = PermissionBlacklist.new(@current_user)
MySchema.execute(query_string, except: filter)
# OR
# `only:` whitelists items:
filter = PermissionWhitelist.new(@current_user)
MySchema.execute(query_string, only: filter)
```

During that query, some elements will be hidden. This means that fields, types, arguments or enum values will be treated as if they were not defined at all.

A filter must respond to `#call(schema_member, ctx)`. When that method returns truthy, the schema member will be blacklisted or whitelisted.

For example, here's an implementation of `PermissionWhitelist` above:

```ruby
class PermissionWhitelist
  def initialize(person)
    @person = person
  end

  # If this returns true, the schema member will be allowed
  def call(schema_member, ctx)
    Permissions.allowed?(person, schema_member)
  end
end
```

The `schema_member` may be any of:

- Type ({{ "GraphQL::BaseType" | api_doc }} and subclasses)
- Field ({{ "GraphQL::Field" | api_doc }})
- Argument ({{ "GraphQL::Argument" | api_doc }})
- Enum value ({{ "GraphQL::EnumType::EnumValue" | api_doc }})

## Use with Metadata

This feature pairs nicely with attaching custom data to types. See the {% internal_link "Extensions Guide","/type_definitions/extensions" %} for information about assigning values to an object's `metadata`.

Then, you can check `metadata` in your filter. For example, to hide fields based on a metadata flag:

```ruby
# Hide secret objects from this user
top_secret = ->(schema_member, ctx) { schema_member.metadata[:top_secret]}
MySchema.execute(query_string, except: top_secret)
```

## Printing a Filtered Schema

You can see how filters will be applied to the schema by printing the schema with that filter. {{ "GraphQL::Schema#to_definition" | api_doc }} accepts `only:` and `except:` options.

For example, to see how the schema looks to a specific user:

```ruby
example_user = User.new(permission: :admin)
filter = PermissionWhitelist.new(example_user)
defn_string = MySchema.to_definition(only: filter)
puts defn_string
# => prints out the filtered schema
```

`Schema#to_definition` also accepts a context which will be passed to the filter as well, for example:

```ruby
context = { current_user: example_user }
puts MySchema.to_definition(only: filter, context: context)
```
