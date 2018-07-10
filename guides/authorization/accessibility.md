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

By default, GraphQL-Ruby will return a simple error to the client if any `.accessible?` checks return false.

You can customize this behavior by overriding {{ "Schema.inaccessible_fields" | api_docs }}, for example:

```ruby
class MySchema < GraphQL::Schema
  # If you have a custom `permission_level` setting on your `GraphQL::Field` class,
  # you can access it here:
  def self.inaccessible_fields(error)
    required_permissions = error.fields.map(&:permission_level).uniq
    # Return a custom error
    GraphQL::AnalysisError.new("You need certain permissions: #{required_permissions.join(", ")}")
  end
end
```

Then, your custom error will be added to the response instead of the default one.
