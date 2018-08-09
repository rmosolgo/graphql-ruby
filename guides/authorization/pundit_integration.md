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

To use the Pundit integration, include modules into your base object and base field classes, then set a default role:

```ruby
class Types::BaseField < GraphQL::Schema::Field
  # Add the Pundit integration:
  include GraphQL::Pro::PunditIntegration::FieldIntegration
  # By default, don't require a role at field-level:
  pundit_role nil
end

# ...

class Types::BaseObject < GraphQL::Schema::Field
  # Hook up the custom field class:
  field_class Types::BaseField
  # Add the Pundit integration:
  include GraphQL::Pro::PunditIntegration::ObjectIntegration
  # By default, require staff:
  pundit_role :staff
  # Or, to require no permissions by default:
  # pundit_role nil
end
```

If you haven't already done so, you should also hook up your base field class to your base interface and base mutation:

```ruby
module Types::BaseInterface
  include GraphQL::Schema::Interface
  field_class Types::BaseField
end

# And:

class Mutations::BaseMutation < GraphQL::Schema::RelayClassicMutation
  field_class Types::BaseField
end
```

Then, in your query context, always include `current_user:`

```ruby
context = {
  current_user: current_user,
  # ...
}
MySchema.execute(..., context: context)
```

This will add the following behaviors to your schema:

- Before any object is exposed by GraphQL, it will use a Pundit policy for that object
- When lists or connections are exposed by GraphQL, it will use a Pundit scope to filter that list

When any Policy method returns `false`, the unauthorized object is passed to {{ "Schema.unauthorized_object" | api_doc }}, as described in {% internal_link "Handling unauthorized objects", "/authorization/authorization#handling-unauthorized-objects" %}.

## Policies and Methods

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

### Default Method

This configuration is inherited, so you can set a default value in the parent class, for example:

```ruby
class Types::BaseObject < GraphQL::Schema::Object
  # By default, restrict all GraphQL objects to internal staff;
  # override this to allow access to any other users.
  pundit_role :staff
end
```

### Bypassing Policies

The integration requires that every object with a `pundit_role` has a corresponding policy class. To allow objects to _skip_ authorization, you can pass `nil` as the role:

```ruby
class Types::PublicProfile < Types::BaseObject
  # Anyone can see this
  pundit_role nil
end
```

## Field-level authorization

Sometimes, some fields require higher permission than others. You can add `pundit_role` to `field(...)` calls to specify a method to call. For example:

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

This way, certain fields can have higher permission requirements.

## Scopes

The Pundit integration adds [Pundit scopes](https://github.com/varvet/pundit#scopes) to GraphQL-Ruby's {% internal_link "list scoping", "/authorization/scoping" %} feature. `ActiveRecord::Relation`s and `Mongoid::Criteria`s will be matched to Policy scopes and filtered accordingly. If a scope is missing, the query will crash rather than risk leaking unfiltered data.

To allow an unscoped relation to be returned from a field, disable scoping with `scope: false`, for example:

```ruby
# Allow anyone to browse the job postings
field :job_postings, [Types::JobPosting], null: false,
  scope: false
```
