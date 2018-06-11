---
layout: guide
doc_stub: false
search: true
section: Mutations
title: Mutation Classes
desc: Use mutation classes to implement behavior, then hook them up to your schema.
class_based_api: true
index: 1
redirect_from:
  - /queries/mutations/
---

GraphQL _mutations_ are special fields: instead of reading data or performing calculations, they may _modify_ the application state. For example, mutation fields may:

- Create, update or destroy records in the database
- Establish associations between already-existing records in the database
- Increment counters
- Create, modify or delete files
- Clear caches

These actions are called _side effects_.

Like all GraphQL fields, mutation fields:

- Accept inputs, called _arguments_
- Return values via _fields_

GraphQL-Ruby includes two classes to help you write mutations:

- {{ "GraphQL::Schema::Mutation" | api_doc }}, a bare-bones base class
- {{ "GraphQL::Schema::RelayClassicMutation" | api_doc }}, a base class with a set of nice conventions that also supports the Relay Classic mutation specification.

Besides those, you can also use the plain {% internal_link "field API", "/type_definitions/objects#fields" %} to write mutation fields.

An additional `null` helper method is provided on classes inheriting from `GraphQL::Schema::Mutation` to allow setting the nullability of the mutation. This is not required and defaults to `true`.

## Example mutation class

You should add a base class to your application, for example:

```ruby
class Mutations::BaseMutation < GraphQL::Schema::RelayClassicMutation
end
```

Then extend it for your mutations:

```ruby
class Mutations::CreateComment < Mutations::BaseMutation
  null true

  argument :body, String, required: true
  argument :post_id, ID, required: true

  field :comment, Types::Comment, null: true
  field :errors, [String], null: false

  def resolve(body:, post_id:)
    post = Post.find(post_id)
    comment = post.comments.build(body: body, author: context[:current_user])
    if comment.save
      # Successful creation, return the created object with no errors
      {
        comment: comment,
        errors: [],
      }
    else
      # Failed save, return the errors to the client
      {
        comment: nil,
        errors: comment.errors.full_messages
      }
    end
  end
end
```

The `#resolve` method should return a hash whose symbols match the `field` names.

(See {% internal_link "Mutation Errors", "/mutations/mutation_errors" %} for more information about returning errors.)

## Hooking up mutations

Mutations must be attached to the mutation root using the `mutation:` keyword, for example:

```ruby
class Types::Mutation < Types::BaseObject
  field :create_comment, mutation: Mutations::CreateComment
end
```
