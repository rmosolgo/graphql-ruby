---
title: Mutations
layout: guide
doc_stub: false
search: true
section: Queries
desc: Creating, Updating and Deleting
index: 3
---

Mutations are queries with side effects. Mutations are used to mutate your data. In order to use mutations you need to define a mutation root type that allows for defining fields that can mutate your data.

```ruby
Schema = GraphQL::Schema.define do
  query QueryType
  mutation MutationType
end
```

Then add your mutations here:

```ruby
MutationType = GraphQL::ObjectType.define do
  name "Mutation"

  field :ratePost, PostType do
    description "Rates a post"
    argument :postId, !types.Int
    argument :stars, !types.Int

    resolve ->(o,args,c) {
      post = Post.find(args[:postId])
      post = post.rate(args[:stars])
      post
    }
  end
end
```

The mutation query would look like:

```graphql
mutation {
  ratePost(postId: 1, stars: 5) {
    stars
  }
}
```


Instead of specifying a long list of arguments, you can also specify an input type. This allows you to have all input fields in an Input type.


```ruby
MutationType = GraphQL::ObjectType.define do
  name "Mutation"

  field :addPost, PostType do
    description "Adds a Post."

    # Use Input Types to define complex argument types
    argument :post, PostInputType
    resolve ->(t, args, c) {
      Post.create!(args[:post])
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

The query would then look like:

```
mutation {
  addPost(post: {title: "Hello Graphql", description: "My graphql post"}) {
    id
    title
  }
}
```

## Nested input types

You can also nest input types. Let's take this a todo list as an example:

```ruby
AddTodoList = GraphQL::Relay::Mutation.define do
  name "AddTodoList"

  # Create an input type for each todo item
  TodoItemInputObjectType = GraphQL::InputObjectType.define do
    name "TodoItem"
    input_field :name,    !types.String
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


The mutation would be like:

```
mutation {
  AddTodoList(todos: [
    {name: "Get Milk", starred: true},
    {name: "Vacuum", starred: false}
  ]) {
    title
    todos {
      name
      starred
    }
  }
}
```
