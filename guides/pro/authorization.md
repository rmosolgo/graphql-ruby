---
layout: guide
doc_stub: false
search: true
section: GraphQL Pro
title: Authorization Framework
desc: GraphQL::Pro's comprehensive access control system, including CanCan and Pundit integrations
index: 2
pro: true
---

`GraphQL::Pro` provides a comprehensive, unified authorization framework for the GraphQL runtime.

Fields and types can be [authorized at runtime](#runtime-authorization), [rejected during validation](#access-authorization), or [hidden entirely](#visibility-authorization). Default authorization can be [applied at schema-level](#fallback-authorization)

`GraphQL::Pro` integrates has out-of-the-box [Pundit support](#pundit) and [CanCan support](#cancan) and supports [custom authorization strategies](#custom-authorization-strategy)

## Configuration

To use authorization, specify an authorization strategy in your schema:

```ruby
MySchema = GraphQL::Schema.define do
  # ...
  authorization :pundit
  # or:
  # authorization :cancan
  # authorization CustomAuthClass
end
```

(See below for details on these strategies.)

Then, provide a `current_user:` in your execution context:

```ruby
# Authenticate somehow:
current_user = User.find(session[:current_user_id])
# Then pass the user as `current_user:`
result = MySchema.execute(query_string, context: { current_user: current_user })
```

`current_user` will be used by the authorization hooks as described below.

### Fallback Authorization

You can specify a fallback auth configuration for the entire schema:

```ruby
MySchema = GraphQL::Schema.define do
  # Always require logged-in users to see anything:
  authorization(..., fallback: { view: :logged_in })
end
```

This rule will be applied to fields which don't have a rule of their own or a rule on their return type.

### Current User

You can customize the `current_user:` context key with `authorization(..., current_user: ...)`:

```ruby
MySchema = GraphQL::Schema.define do
  # Current user is identified as `ctx[:viewer]`
  authorization :pundit, current_user: :viewer
end
```

The authorization will use the specified key to find the current user in `ctx`.

## Runtime Authorization

When a `resolve` function returns an object or list of objects, you can assert that the current user has permission to access that object. The `authorize` keyword defines a runtime permission.

You can specify a permission at __field-level__, for example:

```ruby
# Only allow access to this `balance` if current user is the owner:
field :balance, AccountBalanceType, authorize: :owner

# This is the same:
field :balance, AccountBalanceType do
  authorize :owner
  # ...
end
```

Also, you can specify authentication at __type-level__, for example:

```ruby
AccountBalanceType = GraphQL::ObjectType.define do
  name "AccountBalance"
  # Only billing administrators can see
  # objects of this type:
  authorize :billing_administrator
  # ...
end
```

Field-level and type-level permissions are additive: both checks must pass for a user to access an object.

Type-level permissions are applied according to an object's runtime type (unions and interfaces don't have authorization checks).

If an object doesn't pass permission checks, it is removed from the response. If the object is part of a list, it is removed from the list. You can override this behavior with the [`unauthorized_object` hook](#unauthorized-object).

### Authorize Values by Parent

You can also limit access to fields based on their parent objects with `parent_role:`. For example, to restrict a student's GPA to that student:

```ruby
StudentType = GraphQL::ObjectType.define do
  name "Student"
  field :name, !types.String
  field :gpa, types.Float do
    # only show `Student.gpa` if the
    # student is the viewer:
    authorize parent_role: :current_user
  end
end
```

This way, you can serve a subset of fields based on the object being queried.

### Unauthorized Object

When an object fails a runtime authorization check, the default behavior is:

- return `nil` instead; OR
- if the object is part of a list, remove it from that list.

You can override this behavior by providing a schema-level `unauthorized_object` function:

```ruby
MySchema = GraphQL::Schema.define do
  unauthorized_object ->(obj, ctx) { ... }
end
# OR
MySchema = GraphQL::Schema.define do
  unauthorized_object(MyUnauthorizedObjectHook)
end
```

The function is called with two arguments:

- `obj` is the object which failed a runtime check
- `ctx` is the field context for the failed check

Within the function, you can:

- Write log entries
- Add GraphQL errors, for example:

  ```ruby
  # Add an error to the graphql response:
  err = GraphQL::ExecutionError.new("You don't have permission to see #{obj.name}")
  ctx.add_error(err)
  ```

- Return a different value for the query.

  To return a different value, use `yield` (or `next` for a Proc). For example:

  ```ruby
  module MyUnauthorizedObjectHook
    def self.call(obj, ctx)
      if obj.is_a?(User)
        # Write a log entry
        logger.log("Invalid user access: #{ctx[:current_user]} tried to access #{obj}")
        # Replace an unauthorized object with a null object
        yield(AnonymousUser)
      end
    end
  end
  ```

  For procs, use `next` instead of `yield`:

  ```ruby
  -> (obj, ctx) {
    if obj.is_a?(User)
      # Write a log entry
      logger.log("Invalid user access: #{ctx[:current_user]} tried to access #{obj}")
      # Replace an unauthorized object with a null object
      next(AnonymousUser)
    end
  }
  ```

  (`yield` isn't valid for procs. Long story 😅.)

  Using `yield` allows the library to skip objects entirely when nothing is yielded.

## Access Authorization

You can prevent access to fields and types from certain users. (They can see them, but if they request them, the request is rejected with an error message.) Use the `access:` keyword for this feature.

```ruby
# Non-owners may _see_ these,
# but they may not request them:
field :telephone_number, types.String, access: :owner

AddressType = GraphQL::ObjectType.define do
  name "Address"
  access :owner
  # ...
end
```

When a user requests access to an unpermitted field, GraphQL returns an error message. You can customize this error message by providing an `unauthorized_fields` hook:

```ruby
MySchema = GraphQL::Schema.define do
  # ...
  unauthorized_fields ->(irep_nodes, ctx) {
    GraphQL::AnalysisError.new("Sorry, you're not allowed to see that!")
  }
end
```

The hook should return a {{ "GraphQL::AnalysisError" | api_doc }}. It is called with:

- `irep_nodes`: an array of {{ "GraphQL::InternalRepresentation::Node" | api_doc }}s which represent unpermitted fields in the incoming query.
- `ctx`: the {{ "GraphQL::Query::Context" | api_doc }} (which includes `:current_user`).

## Visibility Authorization

You can hide fields and types from certain users. If they request these types or fields, the error message says that they don't exist at all.

The `view` keyword specifies visibility permission:

```ruby
# These types and fields are
# invisible to non-admins:

# field-level:
field :social_security_number, types.String, view: :admin

# type-level:
PassportApplicationType = GraphQL::ObjectType.define do
  name "PassportApplication"
  view :admin
  # ...
end
```

## Pundit

`GraphQL::Pro` includes built-in support for [Pundit](https://github.com/elabs/pundit):

```ruby
MySchema = GraphQL::Schema.define do
  authorization(:pundit)
end
```

Now, GraphQL will use your `*Policy` classes during execution. To find a policy class:

- [access](#access-authorization) and [visibility](#visibility-authorization) checks use the type name (or return type name) to find a policy class
- [runtime](#runtime-authorization) checks use the object to find a policy class (using Pundit's provided lookup)

You can also specify a custom policy name. Use the `pundit_policy_name:` option, for example:

```ruby
# A pundit policy:
class TotalBalancePolicy
  def initialize(user, obj)
    # ...
  end
  def admin?
    # ...
  end
end

field :balance, AccountBalanceType, authorize: { role: :admin, pundit_policy_name: "TotalBalancePolicy" }
```

The permission is defined as a hash with a `role:` key and `pundit_policy_name:` key. You can pass a hash for `view:` and `access:` too. For [`parent_role:`](#authorize-values-by-parent), you can specify a name with `parent_pundit_policy_name:`.

For `:pundit`, methods will be called with an extra `?`, so

```ruby
view: :viewer
# => will call the policy's `#viewer?` method
```

### Policy Namespace

If you put your policies in a namespace, provide that namespace as `authorize(..., namespace:)`, for example:

```ruby
authorize(:pundit, namespace: Policies)
```

Now, policies will be looked up by name inside `Policies::`, for example:

```ruby
AccountType = GraphQL::ObjectType.define do
  name "Account"
  access :admin # will use Policies::AccountPolicy#admin?
  # ...
end
```

### Policy Scopes

When a resolve function returns an `ActiveRecord::Relation`, the policy's [`Scope` class](https://github.com/elabs/pundit#scopes) will be used if it's available.

See [Scoping](#scoping) for details.

## CanCan

`GraphQL::Pro` includes built-in support for [CanCan](https://github.com/CanCanCommunity/cancancan):

```ruby
MySchema = GraphQL::Schema.define do
  authorization(:cancan)
end
```

GraphQL will initialize your `Ability` class at the beginning of the query and pass permissions to the `#can?` method.

```ruby
field :phone_number, PhoneNumberType, authorize: :view
# => calls `can?(:view, phone_number)`
```

For compile-time checks (`view` and `access`), the object is always `nil`.

```ruby
field :social_security_number, types.String, view: :admin
# => calls `can?(:admin, nil)`
```

### accessible_by

When a resolve function returns an `ActiveRecord::Relation`, the relation's [`accessible_by` method](https://github.com/CanCanCommunity/cancancan/wiki/Fetching-Records) will be used to scope the relation.

See [Scoping](#scoping) for details.

### Custom Ability Class

By default, GraphQL looks for a top-level `Ability` class. You can specify a different class with the `ability_class:` option. For example:

```ruby
MySchema = GraphQL::Schema.define do
  authorization(:cancan, ability_class: Permissions::CustomAbility)
end
```

Now, GraphQL will use `Permissions::CustomAbility#can?` to determine permissions.

## Custom Authorization Strategy

You can provide custom authorization logic by providing a class:

```ruby
MySchema = GraphQL::Schema.define do
  # Custom authorization strategy class:
  authorization(MyAuthStrategy)
end
```

A custom strategy class must implement `#initialize(ctx)` and `#allowed?(gate, object)`. Optionally, it may implement `#scope(gate, relation)`. For example:

```ruby
class MyAuthStrategy
  def initialize(ctx)
    @user = ctx[:custom_user]
  end

  def allowed?(gate, object)
    if object.nil?
      # This is a compile-time check,
      # so no object is available:
      if gate.role == :admin
        @user.admin?
      else
        @user.viewer?
      end
    else
      # This is a runtime check,
      # so we can use this specific object
      @user.can?(gate.role, object)
    end
  end

  def scope(gate, relation)
    # Filter an ActiveRecord::Relation
    # according to `@user` and `gate`
    # ...
  end
end
```

`gate` is the permission setting which responds to:

- `#level`: where this check occurs: `:authorize`, `:view` or `:access`
- `#role`: the value given to `authorize`, `view` or `access`
- `#owner`: the field or type which has this permission check

`object` is either:

- `nil`, if the current check is `:view` or `:access`
- The runtime object, if the current check is `authorize`

For list types, each item of the list is authorized individually.


## Scoping

Database query objects (`ActiveRecord::Relation`s and `Mongoid::Criteria`s) get special treatment. They get passed to _scope handlers_ so that they can be filtered at database level (eg, SQL `WHERE`) instead of Ruby level (eg, `.select`).

`ActiveRecord::Relation`s can be scoped with SQL by authorization strategies. The Pundit integration uses [policy scopes](#policy-scopes) and the CanCan integration uses [`accessible_by`](#accessible_by). [Custom authorization strategies](#custom-authorization-strategy) can implement `#scope(gate, relation)` to apply scoping to `ActiveRecord::Relation`s.

`Mongoid::Criteria`s are supported in the same way by Pundit [policy scopes](#policy-scopes)) and [custom strategy]((#custom-authorization-strategy))'s  `#scope(gate, relation)` methods, but they aren't supported by CanCan (which doesn't support Mongoid, as far as I can tell!).
