---
layout: guide
search: true
section: Authorization
title: Visibility
desc: Programatically hide parts of the GraphQL schema from some users.
index: 1
redirect_from:
- /schema/limiting_visibility
---

With GraphQL-Ruby, it's possible to _hide_ parts of your schema from some users. This isn't exactly part of the GraphQL spec, but it's roughly within the bounds of the spec.

Here are some reasons you might want to hide parts of your schema:

- You don't want non-admin users to know about administration functions of the schema.
- You're developing a new feature and want to make a gradual release to only a few users first.

## Hiding Parts of the Schema

You can customize the visibility of parts of your schema by reimplementing various `visible?` methods:

- Type classes have a `.visible?(context)` class method
- Fields and arguments have a `#visible?(context)` instance method
- Enum values have `#visible?(context)` instance method
- Mutation classes have a `.visible?(context)` class method

These methods are called with the query context, based on the hash you pass as `context:`. If the method returns false, then that member of the schema will be treated as though it doesn't exist for the entirety of the query. That is:

- In introspection, the member will _not_ be included in the result
- In normal queries, if a query references that member, it will return a validation error, since that member doesn't exist

## Object Visibility

Let's say you're working on a new feature which should remain secret for a while. You can implement `.visible?` in a type:

```ruby
class Types::SecretFeature < Types::BaseObject
  def self.visible?(context)
    # only show it to users with the secret_feature enabled
    super && context[:viewer].feature_enabled?(:secret_feature)
  end
end
```

(Always call `super` to inherit the default behavior.)

Now, the following bits of GraphQL will return validation errors:

- Fields that return `SecretFeature`, eg `query { findSecretFeature { ... } }`
- Fragments on `SecretFeature`, eg `Fragment SF on SecretFeature`

And in introspection:

- `__schema { types { ... } }` will not include `SecretFeature`
- `__type(name: "SecretFeature")` will return `nil`
- Any interfaces or unions which normally include `SecretFeature` will _not_ include it
- Any fields that return `SecretFeature` will be excluded from introspection

## Field Visibility

```ruby
class Types::BaseField < GraphQL::Schema::Field
  # Pass `field ..., require_admin: true` to hide this field from non-admin users
  def initialize(*args, require_admin: false, **kwargs, &block)
    @require_admin = require_admin
    super(*args, **kwargs, &block)
  end

  def visible?(ctx)
    # if `require_admin:` was given, then require the current user to be an admin
    super && (@require_admin ? ctx[:viewer]&.admin? : true)
  end
end
```

For this to work, the base field class must be {% internal_link "configured with other GraphQL types", "/type_definitions/extensions.html#customizing-fields" %}.

## Argument Visibility

```ruby
class Types::BaseArgument < GraphQL::Schema::Argument
  # If `require_logged_in: true` is given, then this argument will be hidden from logged-out viewers
  def initialize(*args, require_logged_in: false, **kwargs, &block)
    @require_logged_in = require_logged_in
    super(*args, **kwargs, &block)
  end

  def visible?(ctx)
    super && (@require_logged_in ? ctx[:viewer].present? : true)
  end
end
```

For this to work, the base argument class must be {% internal_link "configured with other GraphQL types", "/type_definitions/extensions.html#customizing-arguments" %}.
