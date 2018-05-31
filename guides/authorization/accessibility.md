---
layout: guide
search: true
section: Authorization
title: Accessibility
desc: Reject queries from unauthorized users if they access certain parts of the schema.
index: 2
---

With GraphQL-Ruby, you can inspect an incoming query, and return a custom error if that query accesses some unauthorized parts of the schema.

This is different from {% internal_link "visibility", "/authorization/visibility" %}, where unauthorized parts of the schema are treated as non-existent. It's also different from {% internal_link "authorization", "/authorization/authorization" %}, which makes checks _while running_, instead of _before running_.

## Preventing Access

You can override some `.accessible?(context)` methods to prevent access to certain members of the schema:

- Type and mutation classes have a `.accessible?(context)` class method
- Arguments and fields have a `.accessible?(context)` instance method

These methods are called with the query context, based on the hash you pass as `context:`.

Whenever that method is implemented to return `false`, the currently-checked field will be collected as inaccessible. For example:

```ruby
class BaseField < GraphQL::Schema::Field
  def initialize(preview:, **kwargs, &block)
    @preview = preview
    super(**kwargs, &block)
  end

  # If this field was marked as preview, hide it unless the current viewer can see previews.
  def accessible?(context)
    if @preview && !context[:viewer].can_preview?
      false
    else
      super
    end
  end
end
```

Now, any fields created with `field(..., preview: true)` will be _visible_ to everyone, but only accessible to users where `.can_preview?` is `true`.

## Adding an Error

TODO:

There is some kind of API where you can define a class method or something that returns an error object, or maybe it raises an error.

Raising is probably better because you get the attached backtrace for debugging.
