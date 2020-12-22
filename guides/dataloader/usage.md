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

## Batch-loading data

With {{ "GraphQL::Dataloader" | api_doc }} in your schema, you're ready to start batch loading data. For example:

```ruby
class Types::Post < Types::BaseObject
  field :author, Types::Author, null: true, description: "The author who wrote this post"

  def author
    # Look up this Post's author by its `belongs_to` association
    GraphQL::Dataloader::ActiveRecordAssociation.load(:author, object)
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
    GraphQL::Dataloader::Http.load("https://api.github.com/users/#{object.github_login}").then do |data|
      data["public_repos"]
    end
  end
end
```

{{ "GraphQL::Dataloader::ActiveRecordAssociation" | api_doc }} and {{ "GraphQL::Dataloader::Http" | api_doc }} are _source classes_ which fields can use to request data. Under the hood, GraphQL will defer the _actual_ data fetching as long as possible, so that batches can be gathered up and sent together.

For a full list of built-in sources, see the {% internal_link "Built-in sources guide", "/dataloader/built_in_sources" %}.

To write custom sources, see the {% internal_link "Custom sources guide", "/dataloader/custom_sources" %}.

## Node IDs

With {{ "GraphQL::Dataloader" | api_doc }}, you can batch-load objects inside `MySchema.object_from_id`:

```ruby
class MySchema < GraphQL::Schema
  def self.object_from_id(id, ctx)
    # TODO update graphql-ruby's defaults to support this
    model_class, model_id = MyIdScheme.decode(id)
    GraphQL::Dataloader::ActiveRecord.load(model_class, model_id)
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

To learn about available sources, see the {% internal_link "built-in sources guide", "/dataloader/built_in_sources" %}. Or, check out the {% internal_link "custom sources guide", "/dataloader/custom_sources" %} to get started with your own sources.
