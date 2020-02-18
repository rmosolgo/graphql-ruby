---
layout: guide
search: true
section: Authorization
title: CanCan Integration
desc: Hook up GraphQL to CanCan abilities
index: 4
pro: true
---


[GraphQL::Pro](https://graphql.pro) includes an integration for powering GraphQL authorization with [CanCan](https://github.com/CanCanCommunity/cancancan).

__Why bother?__ You _could_ put your authorization code in your GraphQL types themselves, but writing a separate authorization layer gives you a few advantages:

- Since the authorization code isn't embedded in GraphQL, you can use the same logic in non-GraphQL (or legacy) parts of the app.
- The authorization logic can be tested in isolation, so your end-to-end GraphQL tests don't have to cover as many possibilities.

## Getting Started

__NOTE__: Requires the latest gems, so make sure your `Gemfile` has:

```ruby
# For CanCanIntegration:
gem "graphql-pro", ">=1.7.11"
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
- [Custom Abilities Class](#custom-abilities-class)

## Authorizing Objects

For each object type, you can assign a required action for Ruby objects of that type. To get started, include the `ObjectIntegration` in your base object class:

```ruby
# app/graphql/types/base_object.rb
class Types::BaseObject < GraphQL::Schema::Object
  # Add the CanCan integration:
  include GraphQL::Pro::CanCanIntegration::ObjectIntegration
  # By default, require `can :read, ...`
  can_can_action(:read)
  # Or, to require no permissions by default:
  # can_can_action(nil)
end
```

Now, anyone fetching an object will need `can :read, ...` for that object.

CanCan configurations are inherited, and can be overridden in subclasses. For example, to allow _all_ viewers to see the `Query` root type:

```ruby
class Types::Query < Types::BaseObject
  # Allow anyone to see the query root
  can_can_action nil
end
```

### Bypassing CanCan

`can_can_action(nil)` will override any inherited configuration and skip CanCan checks for an object, field, argument or mutation.

### Handling Unauthorized Objects

When any CanCan check returns `false`, the unauthorized object is passed to {{ "Schema.unauthorized_object" | api_doc }}, as described in {% internal_link "Handling unauthorized objects", "/authorization/authorization#handling-unauthorized-objects" %}.

## Scopes

#### ActiveRecord::Relation

The CanCan integration adds [CanCan's `.accessible_by`](https://github.com/cancancommunity/cancancan/wiki/Fetching-Records) to GraphQL-Ruby's {% internal_link "list scoping", "/authorization/scoping" %}

To scope lists of interface or union type, include the integration in your base union class and base interface module _and_ set a base `can_can_action`, if desired:

```ruby
class BaseUnion < GraphQL::Schema::Union
  include GraphQL::Pro::CanCanIntegration::UnionIntegration
  # To provide a default action for scoping lists:
  can_can_action :read
end

module BaseInterface
  include GraphQL::Schema::Interface
  include GraphQL::Pro::CanCanIntegration::InterfaceIntegration
  # To provide a default action for scoping lists:
  can_can_action :read
end
```

#### Array

For Arrays, the CanCan integration will use `.select { ... }` to filter items using the `can_can_action` from the lists's type.

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
  # Add the CanCan integration:
  include GraphQL::Pro::CanCanIntegration::FieldIntegration
  # By default, don't require a role at field-level:
  can_can_action nil
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
# app/graphql/mutations/base_mutation.rb
class Mutations::BaseMutation < GraphQL::Schema::RelayClassicMutation
  field_class Types::BaseField
end
```

Then, you can add `can_can_action:` options to your fields:

```ruby
class Types::JobPosting < Types::BaseObject
  # Only allow `can :review_applications, JobPosting` users
  # to see who has applied
  field :applicants, [Types::User], null: true,
    can_can_action: :review_applicants
end
```

It will require the named action (`:review_applicants`) for the object being viewed (a `JobPosting`).

## Authorizing Arguments

Similar to field-level checks, you can require certain permissions to _use_ certain arguments. To do this, add the integration to your base argument class:

```ruby
class Types::BaseArgument < GraphQL::Schema::Argument
  # Include the integration and default to no permissions required
  include GraphQL::Pro::CanCanIntegration::ArgumentIntegration
  can_can_action nil
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

class Mutations::BaseMutation < GraphQL::Schema::RelayClassicMutation
  argument_class Types::BaseArgument
end
```

Now, arguments accept a `can_can_action:` option, for example:

```ruby
class Types::Company < Types::BaseObject
  field :employees, Types::Employee.connection_type, null: true do
    # Only admins can filter employees by email:
    argument :email, String, required: false, can_can_action: :admin
  end
end
```

This will check for `can :admin, Company` (or a similar rule for the `company` being queried) for the current user.

## Authorizing Mutations

There are a few ways to authorize GraphQL mutations with the CanCan integration:

- Add a [mutation-level roles](#mutation-level-roles)
- Run checks on [objects loaded by ID](#authorizing-loaded-objects)

Also, you can configure [unauthorized object handling](#unauthorized-mutations)

#### Setup

Add `MutationIntegration` to your base mutation, for example:

```ruby
class Mutations::BaseMutation < GraphQL::Schema::RelayClassicMutation
  include GraphQL::Pro::CanCanIntegration::MutationIntegration

  # Also, to use argument-level authorization:
  argument_class Types::BaseArgument
end
```

Also, you'll probably want a `BaseMutationPayload` where you can set a default role:

```ruby
class Types::BaseMutationPayload < Types::BaseObject
  # If `BaseObject` requires some permissions, override that for mutation results.
  # Assume that anyone who can run a mutation can read their generated result types.
  can_can_action nil
end
```

And hook it up to your base mutation:

```ruby
class Mutations::BaseMutation < GraphQL::Schema::RelayClassicMutation
  object_class Types::BaseMutationPayload
  field_class Types::BaseField
end
```

#### Mutation-level roles

Each mutation can have a class-level `can_can_action` which will be checked before loading objects or resolving, for example:

```ruby
class Mutations::PromoteEmployee < Mutations::BaseMutation
  can_can_action :run_mutation
end
```

In the example above, `can :run_mutation, Mutations::PromoteEmployee` will be checked before running the mutation. (The currently-running instance of `Mutations::PromoteEmployee` is passed to the ability checker.)

#### Authorizing Loaded Objects

Mutations can automatically load and authorize objects by ID using the `loads:` option.

Beyond the normal [object reading permissions](#authorizing-objects), you can add an additional role for the specific mutation input using a `can_can_action:` option:

```ruby
class Mutations::FireEmployee < Mutations::BaseMutation
  argument :employee_id, ID, required: true,
    loads: Types::Employee,
    can_can_action: :supervise,
end
```

In the case above, the mutation will halt unless the `can :supervise, ...` check returns true. (The fetched instance of `Employee` is passed to the ability checker.)

#### Unauthorized Mutations

By default, an authorization failure in a mutation will raise a Ruby exception. You can customize this by implementing `#unauthorized_by_can_can(owner, value)` in your base mutation, for example:

```ruby
class Mutations::BaseMutation < GraphQL::Schema::RelayClassicMutation
  def unauthorized_by_can_can(owner, value)
    # No error, just return nil:
    nil
  end
end
```

The method is called with:

- `owner`: the `GraphQL::Schema::Argument` instance or mutation class whose role was not satisfied
- `value`: the object which didn't pass for `context[:current_user]`

Since it's a mutation method, you can also access `context` in that method.

Whatever that method returns will be treated as an early return value for the mutation, so for example, you could return {% internal_link "errors as data", "/mutations/mutation_errors" %}:

```ruby
class Mutations::BaseMutation < GraphQL::Schema::RelayClassicMutation
  field :errors, [String], null: true

  def unauthorized_by_can_can(owner, value)
    # Return errors as data:
    { errors: ["Missing required permission: #{owner.can_can_action}, can't access #{value.inspect}"] }
  end
end
```

## Custom Abilities Class

By default, the integration will look for a top-level `::Ability` class.

If you're using a different class, provide an instance ahead-of-time as `context[:can_can_ability]`

For example, you could _always_ add one in your schema's `#execute` method:

```ruby
class MySchema < GraphQL::Schema
  # Override `execute` to provide a custom Abilities instance for the CanCan integration
  def self.execute(*args, context: {}, **kwargs)
    # Assign `context[:can_can_ability]` to an instance of our custom class
    context[:can_can_ability] = MyAuthorization::CustomAbilitiesClass.new(context[:current_user])
    super
  end
end
```
