---
layout: guide
doc_stub: false
search: true
section: GraphQL Pro
title: Stable Cursors for ActiveRecord
desc: Value-based cursors for stable pagination over ActiveRecord::Relations
index: 5
pro: true
---

`GraphQL::Pro` includes a mechanism for serving _stable_ cursors for `ActiveRecord::Relation`s based on column values. If objects are created or destroyed during pagination, the list of items won't be disrupted.

A new `RelationConnection` is applied by default. It is backwards-compatible with existing offset-based cursors. See ["Opting Out"](#opting-out) below if you wish to continue using offset-based pagination.

To enforce the opacity of your cursors, consider an {% internal_link "encrypted encoder","/pro/encoders" %}.

## What's the difference?

The default `RelationConnection` (which turns an `ActiveRecord::Relation` into a Relay-compatible connection) uses _offset_ as a cursor. This naive approach is sufficient for many cases, but it's subject to a specific set of bugs.

Let's say you're looking at the second page of 10 items (`LIMIT 10 OFFSET 10`). During that time, one of the items on page 1 is deleted. When you navigate to page 3 (`LIMIT 10 OFFSET 20`), you'll actually _miss_ one item. The entire list shifted "up" one position when a previous item was deleted.

To solve this bug, we should use a _value_ to page through items (instead of _offset_). For example, if items are ordered by `id`, use the `id` for pagination:

```sql
LIMIT 10                      -- page 1
WHERE id > :last_id LIMIT 10  -- page 2
```

This way, even when items are added or removed, pagination will continue without interruption.

For more information about this issue, see ["Pagination: You're (Probably) Doing It Wrong"](https://coderwall.com/p/lkcaag/pagination-you-re-probably-doing-it-wrong).

## Implementation Notes

Keep these points in mind when using value-based cursors:

- For a given `ActiveRecord::Relation`, only columns of that specific model can be used in pagination. (This is because column names are turned into `WHERE` conditions.)
- `RelationConnection` may add an additional `primary_key` ordering to ensure that the cursor value is unique. This behavior is inspired by `Relation#reverse_order` which also assumes that `primary_key` is the default sort.

## Grouped Relations

When using a grouped `ActiveRecord::Relation`, include a unique ID in your sort to ensure that each row in the result has a unique cursor. For example:

```ruby
# Bad: If two results have the same `max(price)`,
# they will be identical from a pagination perspective:
Products.select("max(price) as price").group("category_id").order("price")

# Good: `category_id` is used to disambiguate any results with the same price:
Products.select("max(price) as price").group("category_id").order("price, category_id")
```

For ungrouped relations, this issue is handled automatically by adding the model's `primary_key` to the order values.

If you provide an unordered, grouped relation, `GraphQL::Pro::RelationConnection::InvalidRelationError` will be raised because an unordered relation _cannot_ be paginated in a stable way.

## Backwards Compatibility

`GraphQL::Pro`'s `RelationConnection` is backwards-compatible. If it receives an offset-based cursor, it uses that cursor for the next resolution, then returns value-based cursors in the next result.

If you're also switching to {% internal_link "encrypted cursors","/pro/encoders" %}, you'll need a {% internal_link "versioned encoder","/pro/encoders#versioning" %}, too. This way, _both_ unencrypted _and_ encrypted cursors will be accepted! For example:

```ruby
# Define an encrypted encoder for use with cursors:
EncryptedCursorEncoder = MyEncoder = GraphQL::Pro::Encoder.define do
  key("f411f30495fe688cb349d...")
end

# Make a versioned encoder combining new & old
VersionedCursorEncoder = GraphQL::Pro::Encoder.versioned(
  # New encrypted encoder:
  EncryptedCursorEncoder
  # Old plaintext encoder (this is the default):
  GraphQL::Schema::Base64Encoder
)

MySchema = GraphQL::Schema.define do
  # Apply the versioned encoder:
  cursor_encoder(VersionedCursorEncoder)
end
```

Now, _both_ unencrypted and encrypted cursors will be accepted.

## Opting Out

If you don't want `GraphQL::Pro`'s new cursor behavior, re-register the offset-based `RelationConnection`:

```ruby
MySchema = GraphQL::Schema.define { ... }
# Always use the offset-based connection, override `GraphQL::Pro::RelationConnection`
GraphQL::Relay::BaseConnection.register_connection_implementation(
  ActiveRecord::Relation, GraphQL::Relay::RelationConnection
)
```

## ActiveRecord Versions

`GraphQL::Pro::RelationConnection` supports ActiveRecord `>= 4.1.0`.
