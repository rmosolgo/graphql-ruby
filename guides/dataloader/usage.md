---
layout: guide
doc_stub: false
search: true
section: Dataloader
title: Usage
desc: Getting started with GraphQL::Dataloader
index: 1
---

To add {{ "GraphQL::Dataloader" | api_doc }} to your schema, attach it with `use`:

```ruby
class MySchema < GraphQL::Schema
  # ...
  use GraphQL::Dataloader
end
```

By default, {{ "GraphQL::Dataloader" | api_doc }} will load data in different threads. To disable this (for example, if your application isn't threadsafe), add `threaded: false`:

```ruby
class MySchema < GraphQL::Schema
  # ...
  # For applications that aren't threadsafe:
  use GraphQL::Dataloader, threaded: false
end
```

Multi-threaded loading (enabled default) also requires the [`concurrent-ruby` gem](https://github.com/ruby-concurrency/concurrent-ruby) in your project. Add to your Gemfile:

```ruby
gem "concurrent-ruby"
```

## Batch-loading data

With {{ "GraphQL::Dataloader" | api_doc }} in your schema, you're ready to start batch loading data. For example:

```ruby
class Types::Post < Types::BaseObject
  field :author, Types::Author, null: true, description: "The author who wrote this post"

  def author
    # Look up this Post's author by its `belongs_to` association
    dataloader.belongs_to(object, :author)
  end
end
```

Or, load data from a URL:

```ruby
class Types::User < Types::BaseObject
  field :github_repos_count, Integer, null: true,
    description: "The number of repos this person has on GitHub"

  def github_repos_count
    # Fetch some JSON, then return one of the values from it.
    dataloader.http.get("https://api.github.com/users/#{object.github_login}").then do |data|
      data["public_repos"]
    end
  end
end
```

For a full list of built-in loaders, see the {% internal_link "Built-in loaders guide", "/dataloader/built_in_loaders" %}.

To write custom loaders, see the {% internal_link "Custom loaders guide", "/dataloader/custom_loaders" %}.

## Node IDs

With {{ "GraphQL::Dataloader" | api_doc }}, you can batch-load objects inside `MySchema.object_from_id`:

```ruby
class MySchema < GraphQL::Schema
  def self.object_from_id(id, ctx)
    # TODO update graphql-ruby's defaults to support this
    model_class, model_id = MyIdScheme.decode(id)
    dataloader.find_record(model_class, model_id)
  end
end
```

This way, even `loads:` IDs will be batch loaded, for example:

```ruby
class Types::Query < Types::BaseObject
  field :post, Types::Post, null: true,
    description: "Look up a post by ID" do
      argument :id, ID, required: true, loads: Types::Post, as: :post
    end
  end

  def post(post:)
    post
  end
end
```
