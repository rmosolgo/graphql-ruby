---
layout: guide
doc_stub: false
search: true
section: Fields
title: Wrapping Resolve Functions
desc: Modify execution by wrapping each field's resolve function
index: 5
---

You can modify field resolution by applying wrappers to the resolve functions. Wrappers can also be applied by {% internal_link "field instrumentation","/fields/instrumentation.html" %}.

For example, you can apply runtime authorization checks. Let's say you're exposing documents in your API:

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
