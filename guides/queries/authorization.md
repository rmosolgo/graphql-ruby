---
layout: guide
search: true
title: Queries — Authorization
---

GraphQL offers a few ways to ensure that clients access data according to their permissions.

- __Query analyzers__ can assert that the query is valid before running it.
- __Resolve wrappers__ can assert that returned objects are permitted to a given user.

## Resolve Wrapper

Sometimes, you can only check permissions when you have the _actual_ object. Let's say you're exposing documents in your API:

```ruby
field :documents, types[DocumentType] do
  resolve ->(obj, args, ctx) {
    documents = obj.documents
    # sort, filter, etc
    # return the documents:
    documents
  }
end
```

You can "wrap" this resolve function to assert that the documents are ok for the current user:

```ruby
# Take a resolve function and call it.
# Then, check that the result includes permitted records _only_.
# @return [Proc] a new resolve function that checks the return values
def assert_allowed_documents(resolve_func)
  ->(obj, args, ctx) {
    documents = resolve_func.call(obj, args, ctx)
    current_user = ctx[:current_user]

    if documents.all? { |d| current_user.can_view?(d) }
      documents
    else
      nil
    end
  }
end

# ...

field :documents, types[DocumentType] do
  # wrap the resolve function with your assertion
  resolve assert_allowed_documents(->(obj, args, ctx) {
    # ...
  })
end
```

This way, you can "catch" the returned value before giving it to a client.

This approach can be further parameterized by implementing it as a class, for example:

```ruby
# Assert that the current user has `permission` on the return value of `block`
class PermissionAssertion
  # Get a permission level and the "inner" resolve function
  def initialize(permission, resolve_func)
    @permission = permission
    @resolve_func = resolve_func
  end

  # GraphQL will call this, so delegate to the "inner" resolve function
  # and check the return value
  def call(obj, args, ctx)
    value = @resolve_func.call(obj, args, ctx)
    current_user = ctx[:current_user]
    if current_user.can?(@permission, value)
      value
    else
      nil
    end
  end
end

# ...

# Apply this class to the resolve function:
field :documents, types[DocumentType] do
  resolve PermissionAssertion.new(:view, ->(obj, args, ctx) {
    # ...
  })
end
```
