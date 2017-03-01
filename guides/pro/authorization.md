---
title: GraphQL::Pro — Authorization Framework
---

`GraphQL::Pro` provides a comprehensive, unified authorization framework for the GraphQL runtime. Authorization can happen in two places:

- __Runtime__: objects from `resolve` functions can be authorized for the current user.
- __"Compile" time__: queries can be rejected if a user requests unauthorized fields or types.

`GraphQL::Pro` supports any authorization scheme and includes built-in [Pundit support](#pundit) and [CanCan support](#cancan)

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

If an object doesn't pass permission checks, it is removed from the response. If the object is part of a list, it is removed from the list.

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

## "Compile" Time Authorization

Before executing a query, GraphQL checks that it is valid. You can assert that users only access fields and types which are allowed to them.

There are two kinds of compile-time authorization:

- __Visibility__: you can hide fields and types from certain users. If they request these types or fields, the error message says that they don't exist.  
- __Accessibility__: you can prevent access of fields and types from certain users. (They can see them, but if they request them, the request is rejected with an error message.)

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

The `access` keyword specifies accessibility permission:

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

## Authorization Strategies

You can choose a built-in strategy or provide custom logic by providing a class:

```ruby
MySchema = GraphQL::Schema.define do
  # choose one:
  authorization(:pundit)
  # or:
  authorization(:cancan)
  # or:
  authorization(MyAuthStrategy)
end
```

As described below, `GraphQL::Pro` includes two built-in strategies, `:pundit` and `:cancan`.

A custom strategy class must implement `#initialize(ctx)` and `#allowed?(gate, object)`. For example:

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

## Pundit

`GraphQL::Pro` includes built-in support for [Pundit](https://github.com/elabs/pundit):

```ruby
MySchema = GraphQL::Schema.define do
  authorization(:pundit)
end
```

Now, GraphQL will use your `*Policy` classes during execution. To find a policy class:

- "Compile"-time checks use the type name (or return type name) to find a policy class
- Runtime checks use the object to find a policy class (using Pundit's provided lookup)

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

The permission is defined as a hash with a `role:` key and `pundit_policy_name:` key. You can pass a hash for `view:` and `access:` too. For `parent_role:`, you can specify a name with `parent_pundit_policy_name:`.

For `:pundit`, methods will be called with an extra `?`, so

```ruby
view: :viewer
# => will call the policy's `#viewer?` method
```

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

### Custom Ability Class

By default, GraphQL looks for a top-level `Ability` class. You can specify a different class with the `ability_class:` option. For example:

```ruby
MySchema = GraphQL::Schema.define do
  authorization(:cancan, ability_class: Permissions::CustomAbility)
end
```

Now, GraphQL will use `Permissions::CustomAbility#can?` to determine permissions.
