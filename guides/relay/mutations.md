---
layout: guide
doc_stub: false
search: true
title: Mutations
section: Relay
desc: Implement Relay-compliant mutation fields
index: 2
---


**NOTE**: See {% internal_link "Mutation Classes", "/mutations/mutation_classes" %} for an updated mutation API.

------

Relay uses a [strict mutation API](https://facebook.github.io/relay/docs/en/mutations.html) for modifying the state of your application. This API makes mutations predictable to the client.

On the client-side, Relay also requires you to specify how it should interpret the response from your GraphQL server, which may require your server-side mutations to return payloads with specific fields.

## Mutation root

To add mutations to your GraphQL schema, define a mutation type and pass it to your schema:

```ruby
# Define the mutation type
class MutationType < GraphQL::Schema::Object
  # ...
end

# and pass it to the schema
class MySchema < GraphQL::Schema
  query QueryType
  mutation MutationType
end
```

Like `QueryType`, `MutationType` is a root of the schema.

## Mutation fields

Members of `MutationType` are _mutation fields_. For GraphQL in general, mutation fields are identical to query fields _except_ that they have side-effects (which mutate application state, eg, update the database).

For Relay-compliant GraphQL, a mutation field must comply to a strict API. `GraphQL::Relay` includes a mutation definition helper (see below) to make it simple.

After defining a mutation (see below), add it to your mutation type:

```ruby
class MutationType < GraphQL::Schema::Object
  # Add the mutation's derived field to the mutation type
  field :add_comment, field: AddCommentMutation.field
  # ...
end
```

## Relay mutations

To define a mutation, use `GraphQL::Relay::Mutation.define`. Inside the block, you should configure:

  - `name`, which will name the mutation field & derived types
  - `input_field`s, which will be applied to the derived `InputObjectType`
  - `return_field`s, which will be applied to the derived `ObjectType`
  - `resolve(->(object, inputs, ctx) { ... })`, the mutation which will actually happen

Whereas you can have whatever combination and number of `input_field`s you wish, Relay expects different return fields when using certain mutator configuration you use on the client-side:

- `FIELDS_CHANGE` — expects a field for the mutated object.
- `NODE_DELETE` — expects fields for the destroyed object and the destroyed object’s parent
- `RANGE_ADD` — expects fields for the newly created edge (see below) and its parent
- `RANGE_DELETE` - expects fields for the ID(s) of the deleted children and their parent

For example:

```ruby
AddCommentMutation = GraphQL::Relay::Mutation.define do
  # Used to name derived types, eg `"AddCommentInput"`:
  name "AddComment"

  # Accessible from `inputs` in the resolve function:
  input_field :postId, !types.ID
  input_field :authorId, !types.ID
  input_field :body, !types.String

  # The result has access to these fields,
  # resolve must return a hash with these keys.
  # On the client-side this would be configured
  # as RANGE_ADD mutation, so our returned fields
  # must conform to that API.
  return_field :post, PostType
  return_field :commentsConnection, CommentType.connection_type
  return_field :newCommentEdge, CommentType.edge_type

  # The resolve proc is where you alter the system state.
  resolve ->(object, inputs, ctx) {
    post = Post.find(inputs[:postId])
    comments = post.comments
    new_comment = comments.build(authorId: inputs[:authorId], body: inputs[:body])
    new_comment.save!

    # Use this helper to create the response that a
    # client-side RANGE_ADD mutation would expect.
    range_add = GraphQL::Relay::RangeAdd.new(
      parent: post,
      collection: comments,
      item: new_comment,
      context: ctx,
    )

    response = {
      post: post,
      commentsConnection: range_add.connection,
      newCommentEdge: range_add.edge,
    }
  }
end
```

## Derived Objects

`graphql-ruby` uses your mutation to define some members of the schema. Under the hood, GraphQL creates:

- A field for your schema's `mutation` root, as `AddCommentMutation.field`
- A derived `InputObjectType` for input values, as `AddCommentMutation.input_type`
- A derived `ObjectType` for return values, as `AddCommentMutation.return_type`

Each of these derived objects maintains a reference to the parent `Mutation` in the `mutation` attribute. So you can access it from the derived object:

```ruby
# Define a mutation:
AddCommentMutation = GraphQL::Relay::Mutation.define { ... }
# Get the derived input type:
AddCommentMutationInput = AddCommentMutation.input_type
# Reference the parent mutation:
AddCommentMutationInput.mutation
# => #<GraphQL::Relay::Mutation @name="AddComment">
```

## Mutation Resolution

In the mutation's `resolve` function, it can mutate your application state (eg, writing to the database) and return some results.

`resolve` is called with:

- `object`, which is the `root_value:` provided to `Schema.execute`
- `inputs`, which is a hash whose keys are the ones defined by `input_field`. (This value comes from `args[:input]`.)
- `ctx`, which is the query context

It must return a `hash` whose keys match your defined `return_field`s. (Or, if you specified a `return_type`, you can return an object suitable for that type.)

### Specify a Return Type

Instead of specifying `return_field`s, you can specify a `return_type` for a mutation. This type will be used to expose the object returned from `resolve`.

```ruby
CreateUser = GraphQL::Relay::Mutation.define do
  return_type UserMutationResultType
  # ...
  resolve ->(obj, input, ctx) {
    user = User.create(input)
    # this object will be treated as `UserMutationResultType`
    UserMutationResult.new(user, client_mutation_id: input[:clientMutationId])
  }
end
```

If you provide your own return type, it's up to you to support `clientMutationId`

### Specifying a Return Interface

An alternative to defining the whole return type from scratch is to specify `return_interfaces`.
The result of the `resolve` block will be passed to the field definitions in the interfaces,
and both interface-specific and mutation-specific fields will be available to clients.


```ruby
MutationResult = GraphQL::InterfaceType.define do
  name "MutationResult"
  field :success, !types.Boolean
  field :notice, types.String
  field :errors, types[ValidationError]
end

CreatePost = GraphQL::Relay::Mutation.define do
  # ...
  return_field :slug, types.String
  return_field :url, types.String
  return_interfaces [MutationResult],

  # clientMutationId will also be available automatically
  resolve ->(obj, input, ctx) {
    post, notice = Post.create_with_input(...)
    {
      success: post.persisted?
      notice: notice
      url: post.url
      errors: post.errors
    }
  }
end
```
