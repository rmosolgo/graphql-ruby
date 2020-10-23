---
layout: guide
doc_stub: false
search: true
section: Mutations
title: Mutation Classes
desc: Use mutation classes to implement behavior, then hook them up to your schema.
index: 1
redirect_from:
  - /queries/mutations/
  - /relay/mutations/
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

If you used the {% internal_link "install generator", "/schema/generators#graphqlinstall" %}, a base mutation class will already have been generated for you. If that's not the case, you should add a base class to your application, for example:

```ruby
class Mutations::BaseMutation < GraphQL::Schema::RelayClassicMutation
  # Add your custom classes if you have them:
  # This is used for generating payload types
  object_class Types::BaseObject
  # This is used for return fields on the mutation's payload
  field_class Types::BaseField
  # This is used for generating the `input: { ... }` object type
  input_object_class Types::BaseInputObject
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

## Auto-loading arguments

In most cases, a GraphQL mutation will act against a given global relay ID. Loading objects from these global relay IDs can require a lot of boilerplate code in the mutation's resolver.

An alternative approach is to use the `loads:` argument when defining the argument:

```ruby
class Mutations::AddStar < Mutations::BaseMutation
  argument :post_id, ID, required: true, loads: Types::Post

  field :post, Types::Post, null: true

  def resolve(post:)
    post.star

    {
      post: post,
    }
  end
end
```

By specifying that the `post_id` argument loads a `Types::Post` object type, a `Post` object will be loaded via {% internal_link "`Schema#object_from_id`", "/schema/definition.html#object-identification-hooks" %} with the provided `post_id`.

All arguments that end in `_id` and use the `loads:` method will have their `_id` suffix removed. For example, the mutation resolver above receives a `post` argument which contains the loaded object, instead of a `post_id` argument.

The `loads:` option also works with list of IDs, for example:

```ruby
class Mutations::AddStars < Mutations::BaseMutation
  argument :post_ids, [ID], required: true, loads: Types::Post

  field :posts, [Types::Post], null: true

  def resolve(posts:)
    posts.map(&:star)

    {
      posts: posts,
    }
  end
end
```

All arguments that end in `_ids` and use the `loads:` method will have their `_ids` suffix removed and an `s` appended to their name. For example, the mutation resolver above receives a `posts` argument which contains all the loaded objects, instead of a `post_ids` argument.

In some cases, you may want to control the resulting argument name. This can be done using the `as:` argument, for example:

```ruby
class Mutations::AddStar < Mutations::BaseMutation
  argument :post_id, ID, required: true, loads: Types::Post, as: :something

  field :post, Types::Post, null: true

  def resolve(something:)
    something.star

    {
      post: something
    }
  end
end
```

In the above examples, `loads:` is provided a concrete type, but it also supports abstract types (i.e. interfaces and unions).
