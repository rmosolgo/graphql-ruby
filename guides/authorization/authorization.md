---
layout: guide
search: true
section: Authorization
title: Authorization
desc: During execution, check if the current user has permission to access retrieved objects.
index: 3
---

While a query is running, you can check each object to see whether the current user is authorized to interact with that object. If the user is _not_ authorized, you can handle the case with an error.

## Adding Authorization Checks

Schema members have `.authorized?(value, context)` methods which will be called during execution:

- Type and mutation classes have `.authorized?(value, context)` class methods
- Fields and arguments have `#authorized?(value, context)` instance methods

These methods are called with:

- `value`: the object from your application which was returned from a field
- `context`: the query context, based on the hash passed as `context:`

When you implement this method to return `false`, the query will be halted, for example:

```ruby
class Types::Friendship < Types::BaseObject
  # You can only see the details on a `Friendship`
  # if you're one of the people involved in it.
  def self.authorized?(object, context)
    super && (object.to_friend == context[:viewer] || object.from_friend == context[:viewer])
  end
end
```

(Always call `super` to get the default checks, too.)

Now, whenever an object of type `Friendship` is going to be returned to the client, it will first go through the `.authorized?` method. If that method returns false, the field will get `nil` instead of the original object, and you may handle that case with an error (see below).

## Handling Unauthorized Objects

**TODO**

There should be some way to customize the handling of unauthorized objects.
