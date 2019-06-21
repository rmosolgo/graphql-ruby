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

__NOTE:__ A new {% internal_link "Pundit integration", "/authorization/pundit_integration" %} and {% internal_link "CanCan integration",
"/authorization/can_can_integration" %} are available. They leverage GraphQL-Ruby's new {% internal_link "built-in auth", "/authorization/overview" %} system and has better support for inheritance and customization. If possible, use those instead!

------

`GraphQL::Pro` provides a comprehensive, unified authorization framework for the GraphQL runtime.

Fields and types can be [authorized at runtime](#runtime-authorization), [rejected during validation](#access-authorization), or [hidden entirely](#visibility-authorization). Default authorization can be [applied at schema-level](#fallback-authorization)

`GraphQL::Pro` integrates out-of-the-box [Pundit support](#pundit) and [CanCan support](#cancan) and supports [custom authorization strategies](#custom-authorization-strategy)

## Configuration

To use authorization, specify an authorization strategy in your schema:

```ruby
class Schema < GraphQL::Schema
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
class Schema < GraphQL::Schema
  # Always require logged-in users to see anything:
  authorization(..., fallback: { view: :logged_in })
end
```

This rule will be applied to fields which don't have a rule of their own or a rule on their return type.

### Current User

You can customize the `current_user:` context key with `authorization(..., current_user: ...)`:

```ruby
class Schema < GraphQL::Schema
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
class AccountBalanceType < GraphQL::Schema::Object
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
class StudentType < GraphQL::Schema::Object
  field :name, String, null: false
  field :gpa, Float, null: true do 
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
class Schema < GraphQL::Schema
  # Override this hook to handle cases when `authorized?` returns false for an object:
  def self.unauthorized_object(error)
    # Add a top-level error to the response instead of returning nil:
    raise GraphQL::ExecutionError, "An object of type #{error.type.graphql_name} was hidden due to permissions"
  end
end
```

The function is used to handle unauthorized objects:

You could refer to the basic authorization {% internal_link "guide", "/authorization/authorization" %} for more details. 

## Access Authorization

You can prevent access to fields and types from certain users. (They can see them, but if they request them, the request is rejected with an error message.) Use the `access:` keyword for this feature.

```ruby
class AddressType < GraphQL::Schema::Object
  # Non-owners may see this type, but they may not request them. 
  access :owner

  # Non-owners may see this field, but they may not request them. 
  field :telephone_number, String, null: true, access: :owner
end
```

When a user requests access to an unpermitted field, GraphQL returns an error message. You can customize this error message by providing an `unauthorized_fields` hook:

```ruby
class Schema < GraphQL::Schema
  # Override this hook to handle cases when `authorized?` returns false for a field:
  def self.unauthorized_field(error)
    # Add a top-level error to the response instead of returning nil:
    raise GraphQL::ExecutionError, "The field #{error.field.graphql_name} on an object of type #{error.type.graphql_name} was hidden due to permissions"
  end  
end
```

The function is used to handle unauthorized fields:

You could refer to the basic authorization {% internal_link "guide", "/authorization/authorization" %} for more details. 

## Visibility Authorization

You can hide fields and types from certain users. If they request these types or fields, the error message says that they don't exist at all.

The `view` keyword specifies visibility permission:

```ruby
class PassportApplicationType < GraphQL::Schema::Object
  # Every field on this type is invisible to non-admins
  view :admin 

  # This field is invisible to non-admins
  field :social_security_number, String, null: true, view: :admin
  # ...
end
```

## Pundit

__NOTE:__ A new {% internal_link "Pundit integration", "/authorization/pundit_integration" %} is available. It leverages GraphQL-Ruby's new {% internal_link "built-in auth", "/authorization/overview" %} system and has better support for inheritance and customization. If possible, use that one instead!

`GraphQL::Pro` includes built-in support for [Pundit](https://github.com/elabs/pundit):

```ruby
class Schema < GraphQL::Schema
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
class AccountType < GraphQL::Schema::Object
  access :admin # will use Policies::AccountPolicy#admin?
  # ...
end
```

### Policy Scopes

When a resolve function returns an `ActiveRecord::Relation`, the policy's [`Scope` class](https://github.com/elabs/pundit#scopes) will be used if it's available.

See [Scoping](#scoping) for details.

## CanCan

__NOTE:__ A new {% internal_link "CanCan integration", "/authorization/can_can_integration" %} is available. It leverages GraphQL-Ruby's new {% internal_link "built-in auth", "/authorization/overview" %} system and has better support for inheritance and customization. If possible, use that one instead!

`GraphQL::Pro` includes built-in support for [CanCan](https://github.com/CanCanCommunity/cancancan):

```ruby
class Schema < GraphQL::Schema
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
field :social_security_number, String, null: true, view: :admin
# => calls `can?(:admin, nil)`
```

### accessible_by

When a resolve function returns an `ActiveRecord::Relation`, the relation's [`accessible_by` method](https://github.com/CanCanCommunity/cancancan/wiki/Fetching-Records) will be used to scope the relation.

See [Scoping](#scoping) for details.

### Custom Ability Class

By default, GraphQL looks for a top-level `Ability` class. You can specify a different class with the `ability_class:` option. For example:

```ruby
class Schema < GraphQL::Schema
  authorization(:cancan, ability_class: Permissions::CustomAbility)
end
```

Now, GraphQL will use `Permissions::CustomAbility#can?` to determine permissions.

## Custom Authorization Strategy

You can provide custom authorization logic by providing a class:

```ruby
class Schema < GraphQL::Schema
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
