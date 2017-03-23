---
title: Queries — Mutations
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

## Nested mutations

You can also nest mutations allowing to embed arrays of input types. Let take this todo list
as an example.

```ruby
AddTodoList = GraphQL::Relay::Mutation.define do
  name "AddTodoList"
 
  # Create an input type for each item
  TodoItemInputObjectType = GraphQL::InputObjectType.define do
    name "TodoItem"
    input_field :name, !types.String
    input_field :starred, !types.Boolean
  end

  # Mutation takes an array of them:
  input_field :todos, !types[!TodoItemInputObjectType]
    end
end
```
