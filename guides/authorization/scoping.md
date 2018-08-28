---
layout: guide
search: true
section: Authorization
title: Scoping
desc: Filter lists to match the current viewer and context
index: 4
---


_Scoping_ is a complementary consideration to authorization. Rather than checking "can this user see this thing?", scoping takes a list of items filters it to the subset which is appropriate for the current viewer and context. The resulting subset is authorized as normal, and, assuming that it was properly scoped, each item should pass authorization checks.

For similar features, see [Pundit scopes](https://github.com/varvet/pundit#scopes) and [Cancan's `.accessible_by`](https://github.com/cancancommunity/cancancan/wiki/Fetching-Records).

## `scope:` option

Fields accept a `scope:` option to enable (or disable) scoping, for example:

```ruby
field :products, [Types::Product], scope: true
# Or
field :all_products, [Types::Product], scope: false
```

For __list__ and __connection__ fields, `scope: true` is the default. For all other fields, `scope: false` is the default. You can override this by using the `scope:` option.

## `.scope_items(items, ctx)` method

Type classes may implement `.scope_items(items, ctx)`. This method is called when a field has `scope: true`. For example,

```ruby
field :products, [Types::Product] # has `scope: true` by default
```

Will call:

```ruby
class Types::Product < Types::BaseObject
  def self.scope_items(items, context)
    # filter items here
  end
end
```

The method should return a new list with only the appropriate items for the current `context`.
