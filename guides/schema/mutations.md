---
title: Schema — Mutations
---

## Mutations

Registering a mutation root allows to define fields that can mutate your data.

```ruby
Schema = GraphQL::Schema.define do
  query QueryRoot
  mutation MutationRoot
end

MutationRoot = GraphQL::ObjectType.define do
  name "Mutation"

  field :addPost, Post do
    description "Adds a Post."

    # Use Input Types to define complex argument types
    argument :post, PostInputType
    resolve ->(t, args, c) {
      title = args['post']['title']
      description = args['post']['description']
      Post.create(title: title, description: description)
    }
  end
end

PostInputType = GraphQL::InputObjectType.define do
  name "PostInputType"
  description "Properties for creating a Post"

  argument :title, !types.String do
    description "Title of the post."
  end

  argument :description, types.String do
    description "Description of the post."
  end
end
```

## Nested input types

You can also nest input types. Let's take this a todo list as an example:

```ruby
AddTodoList = GraphQL::Relay::Mutation.define do
  name "AddTodoList"

  # Create an input type for each todo item
  TodoItemInputObjectType = GraphQL::InputObjectType.define do
    name "TodoItem"
    input_field :name, !types.String
    input_field :starred, !types.Boolean
  end

  # Mutation takes an array of those
  input_field :todos, !types[!TodoItemInputObjectType]

  resolve ->(obj, input, ctx) {
    input[:todos]
    # [
    #   {name: "Get Milk", starred: true},
    #   {name: "Vacuum", starred: false},
    # ]
    # ... create each todo...
  }
end
```
