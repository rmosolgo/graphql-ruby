---
layout: guide
search: true
section: Authorization
title: Pundit Integration
desc: Hook up GraphQL to Pundit policies
index: 4
pro: true
---

[GraphQL::Pro](http://graphql.pro) includes an integration for powering GraphQL authorization with [Pundit](https://github.com/varvet/pundit) policies.

__Why bother?__ You _could_ put your authorization code in your GraphQL types themselves, but writing a separate authorization layer gives you a few advantages:

- Since the authorization code isn't embedded in GraphQL, you can use the same logic in non-GraphQL (or legacy) parts of the app.
- The authorization logic can be tested in isolation, so your end-to-end GraphQL tests don't have to cover as many possibilities.

## Getting Started

__NOTE__: Requires the latest gems, so make sure your `Gemfile` has:

```ruby
# For PunditIntegration:
gem "graphql-pro", ">=1.7.9"
# For list scoping:
gem "graphql", ">=1.8.7"
```

Then, `bundle install`.

Whenever you run queries, include `:current_user` in the context:

```ruby
context = {
  current_user: current_user,
  # ...
}
MySchema.execute(..., context: context)
```

And read on about the different features of the integration:

- [Authorizing Objects](#authorizing-objects)
- [Scoping Lists and Connections](#scopes)
- [Authorizing Fields](#authorizing-fields)
- [Authorizing Arguments](#authorizing-arguments)
- [Authorizing Mutations](#authorizing-mutations)

## Authorizing Objects

You can specify Pundit roles that must be satisfied in order for viewers to see objects of a certain type. To get started, include the `ObjectIntegration` in your base object class:

```ruby
# app/graphql/types/base_object.rb
class Types::BaseObject < GraphQL::Schema::Object
  # Add the Pundit integration:
  include GraphQL::Pro::PunditIntegration::ObjectIntegration
  # By default, require staff:
  pundit_role :staff
  # Or, to require no permissions by default:
  # pundit_role nil
end
```

Now, anyone trying to read a GraphQL object will have to pass the `#staff?` check on that object's policy.

Then, each child class can override that parent configuration. For example, allow _all_ viewers to read the `Query` root:

```ruby
class Types::Query < Types::BaseObject
  # Allow anyone to see the query root
  pundit_role nil
end
```

#### Policies and Methods

For each object returned by GraphQL, the integration matches it to a policy and method.

The policy is found using [`Pundit.policy!`](https://www.rubydoc.info/gems/pundit/Pundit%2Epolicy!), which looks up a policy using the object's class name.

Then, GraphQL will call a method on the policy to see whether the object is permitted or not. This method is assigned in the object class, for example:

```ruby
class Types::Employee < Types::BaseObject
  # Only show employee objects to their bosses,
  # or when that employee is the current viewer
  pundit_role :employer_or_self
  # ...
end
```

That configuration will call `#employer_or_self?` on the corresponding Pundit policy.

#### Bypassing Policies

The integration requires that every object with a `pundit_role` has a corresponding policy class. To allow objects to _skip_ authorization, you can pass `nil` as the role:

```ruby
class Types::PublicProfile < Types::BaseObject
  # Anyone can see this
  pundit_role nil
end
```

#### Handling Unauthorized Objects

When any Policy method returns `false`, the unauthorized object is passed to {{ "Schema.unauthorized_object" | api_doc }}, as described in {% internal_link "Handling unauthorized objects", "/authorization/authorization#handling-unauthorized-objects" %}.

## Scopes

The Pundit integration adds [Pundit scopes](https://github.com/varvet/pundit#scopes) to GraphQL-Ruby's {% internal_link "list scoping", "/authorization/scoping" %} feature. Any list or connection will be scoped. If a scope is missing, the query will crash rather than risk leaking unfiltered data.

To scope lists of interface or union type, include the integration in your base union class and base interface module:

```ruby
class BaseUnion < GraphQL::Schema::Union
  include GraphQL::Pro::PunditIntegration::UnionIntegration
end

module BaseInterface
  include GraphQL::Schema::Interface
  include GraphQL::Pro::PunditIntegration::InterfaceIntegration
end
```

Note that Pundit scopes are best for database relations, but don't play well with Arrays. See below for bypassing Pundit if you want to return an Array.

#### Bypassing scopes

To allow an unscoped relation to be returned from a field, disable scoping with `scope: false`, for example:

```ruby
# Allow anyone to browse the job postings
field :job_postings, [Types::JobPosting], null: false,
  scope: false
```

## Authorizing Fields

You can also require certain checks on a field-by-field basis. First, include the integration in your base field class:

```ruby
# app/graphql/types/base_field.rb
class Types::BaseField < GraphQL::Schema::Field
  # Add the Pundit integration:
  include GraphQL::Pro::PunditIntegration::FieldIntegration
  # By default, don't require a role at field-level:
  pundit_role nil
end
```

If you haven't already done so, you should also hook up your base field class to your base object and base interface:

```ruby
# app/graphql/types/base_object.rb
class Types::BaseObject < GraphQL::Schema::Object
  field_class Types::BaseField
end
# app/graphql/types/base_interface.rb
module Types::BaseInterface
  # ...
  field_class Types::BaseField
end
```

Then, you can add `pundit_role:` options to your fields:

```ruby
class Types::JobPosting < Types::BaseObject
  # Allow signed-in users to browse listings
  pundit_role :signed_in

  # But, only allow `JobPostingPolicy#staff?` users to see
  # who has applied
  field :applicants, [Types::User], null: true,
    pundit_role: :staff
end
```

It will call the named role (eg, `#staff?`) on the parent object's policy (eg `JobPostingPolicy`).

## Authorizing Arguments

Similar to field-level checks, you can require certain permissions to _use_ certain arguments. To do this, add the integration to your base argument class:

```ruby
class Types::BaseArgument < GraphQL::Schema::Argument
  # Include the integration and default to no permissions required
  include GraphQL::Pro::PunditIntegration::ArgumentIntegration
  pundit_role nil
end
```

Then, make sure your base argument is hooked up to your base field and base input object:

```ruby
class Types::BaseField < GraphQL::Schema::Field
  argument_class Types::BaseArgument
  # PS: see "Authorizing Fields" to make sure your base field is hooked up to objects, interfaces and mutations
end

class Types::BaseInputObject < GraphQL::Schema::InputObject
  argument_class Types::BaseArgument
end
```

Now, arguments accept a `pundit_role:` option, for example:

```ruby
class Types::Company < Types::BaseObject
  field :employees, Types::Employee.connection_type, null: true do
    # Only admins can filter employees by email:
    argument :email, String, required: false, pundit_role: :admin
  end
end
```

The role will be called on the parent object's policy, for example `CompanyPolicy#admin?` in the case above.

## Authorizing Mutations

There are a few ways to authorize GraphQL mutations with the Pundit integration:

- Add a [mutation-level roles](#mutation-level-roles)
- Run checks on [objects loaded by ID](#authorizing-loaded-objects)

Also, you can configure [unauthorized object handling](#unauthorized-mutations)

#### Setup

Add `MutationIntegration` to your base mutation, for example:

```ruby
class Mutations::BaseMutation < GraphQL::Schema::Mutation
  include GraphQL::Pro::PunditIntegration::MutationIntegration

  # Also, to use argument-level authorization:
  argument_class Types::BaseArgument
end
```

Also, you'll probably want a `BaseMutationPayload` where you can set a default role:

```ruby
class Types::BaseMutationPayload < Types::BaseObject
  # If `BaseObject` requires some permissions, override that for mutation results.
  # Assume that anyone who can run a mutation can read their generated result types.
  pundit_role nil
end
```

And hook it up to your base mutation:

```ruby
class Mutations::BaseMutation < GraphQL::Schema::RelayClassicMutation
  object_class Types::BaseMutationPayload
end
```

#### Mutation-level roles

Each mutation can have a class-level `pundit_role` which will be checked before loading objects or resolving, for example:

```ruby
class Mutations::PromoteEmployee < Mutations::BaseMutation
  pundit_role :admin
end
```

In the example above, `PromoteEmployeePolicy#admin?` will be checked before running the mutation.

#### Custom Policy Class

By default, Pundit uses the mutation's class name to look up a policy. You can override this by defining `self.policy_class` on your mutation:

```ruby
class Mutations::PromoteEmployee < Mutations::BaseMutation
  def self.policy_class
    ::UserPolicy
  end

  pundit_role :admin
end
```

Now, the mutation will check `UserPolicy#admin?` before running.

Another good approach is to have one policy per mutation. You can implement `self.policy_class` to look up a class _within_ the mutation, for example:

```ruby
class Mutations::BaseMutation < GraphQL::Schema::RelayClassicMutation
  def self.policy_class
    # Look up a nested `Policy` constant:
    self.const_get(:Policy)
  end
end
```

Then, each mutation can define its policy inline, for example:

```ruby
class Mutations::PromoteEmployee < Mutations::BaseMutation
  # This will be found by `BaseMutation.policy_class`, defined above:
  class Policy
    # ...
  end

  pundit_role :admin
end
```

Now, `Mutations::PromoteEmployee::Policy#admin` will be checked before running the mutation.

#### Authorizing Loaded Objects

Mutations can automatically load and authorize objects by ID using the `loads:` option.

Beyond the normal [object reading permissions](#authorizing-objects), you can add an additional role for the specific mutation input using a `pundit_role:` option:

```ruby
class Mutations::FireEmployee < Mutations::BaseMutation
  argument :employee_id, ID, required: true,
    loads: Types::Employee,
    pundit_role: :supervisor,
end
```

In the case above, the mutation will halt unless the `EmployeePolicy#supervisor?` method returns true.

#### Unauthorized Mutations

By default, an authorization failure in a mutation will raise a Ruby exception. You can customize this by implementing `#unauthorized_by_pundit(owner, value)` in your base mutation, for example:

```ruby
class Mutations::BaseMutation < GraphQL::Schema::RelayClassicMutation
  def unauthorized_by_pundit(owner, value)
    # No error, just return nil:
    nil
  end
end
```

The method is called with:

- `owner`: the `GraphQL::Schema::Argument` or mutation class whose role was not satisfied
- `value`: the object which didn't pass for `context[:current_user]`

Since it's a mutation method, you can also access `context` in that method.

Whatever that method returns will be treated as an early return value for the mutation, so for example, you could return {% internal_link "errors as data", "/mutations/mutation_errors" %}:

```ruby
class Mutations::BaseMutation < GraphQL::Schema::RelayClassicMutation
  field :errors, [String], null: true

  def unauthorized_by_pundit(owner, value)
    # Return errors as data:
    { errors: ["Missing required permission: #{owner.pundit_role}, can't access #{value.inspect}"] }
  end
end
```
