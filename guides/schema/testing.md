---
layout: guide
doc_stub: false
search: true
title: Testing
section: Schema
desc: Techniques for testing your GraphQL system
index: 7
---

There are a few ways to test the behavior of your GraphQL schema:

- _Don't_ test the schema, test other objects instead
- Execute GraphQL queries and test the result

## Don't test the schema

The easiest way to test behavior of a GraphQL schema is to extract behavior into separate objects and test those objects in isolation. For Rails, you don't test your models by running controller tests, right? Similarly, you can test "lower-level" parts of the system on their own without running end-to-end tests.

For example, consider a field which calculates its own value:

```ruby
class PostType < GraphQL::Schema::Object
  # ...
  field :is_trending, Boolean, null: false

  def is_trending
    recent_comments = object.comments.where("created_at < ?", 1.day.ago)
    recent_comments.count > 100
  end
end
```

You can refactor this by creating a new class and applying it to your GraphQL schema:

```ruby
# app/models/post/trending.rb
class Post
  class Trending
    TRENDING_COMMENTS_COUNT = 100
    def initialize(post)
      @post = post
    end

    def value
      recent_comments = @post.comments.where("created_at < ?", 1.day.ago)
      recent_comments.count > TRENDING_COMMENTS_COUNT
    end
  end
end

# ....

class PostType < GraphQL::Schema::Object
  # ...
  field :is_trending, Boolean, null: false

  def is_trending
    Post::Trending.new(object).value
  end
end
```

This is an improvement because your behavior is not coupled to your GraphQL schema. Besides that, it's easier to test: you can simply unit test the calculation class. For example:

```ruby
# spec/models/post/trending_spec.rb
RSpec.describe Post::Trending do
  let(:post) { create(:post) }
  let(:trending) { Post::Trending.new(post) }

  describe "#value" do
    context "when there are no recent comments" do
      it "is false" do
        expect(trending.value).to eq(false)
      end
    end

    context "when there are more than 100 recent comments" do
      before do
        101.times { create(:comment, post: post) }
      end

      it "is true" do
        expect(trending.value).to eq(true)
      end
    end
  end
end
```

## Executing GraphQL queries

Sometimes, you really need an end-to-end test. Although it requires a lot of overhead, it's nice to have a "sanity check" on the system as a whole (for example, authorization and database batching).

You can execute queries on your schema in a test. For example, you can set it up like this:

```ruby
RSpec.describe MySchema do
  # You can override `context` or `variables` in
  # more specific scopes
  let(:context) { {} }
  let(:variables) { {} }
  # Call `result` to execute the query
  let(:result) {
    res = MySchema.execute(
      query_string,
      context: context,
      variables: variables
    )
    # Print any errors
    if res["errors"]
      pp res
    end
    res
  }

  describe "a specific query" do
    # provide a query string for `result`
    let(:query_string) { %|{ viewer { name } }| }

    context "when there's no current user" do
      it "is nil" do
        # calling `result` executes the query
        expect(result["data"]["viewer"]).to eq(nil)
      end
    end

    context "when there's a current user" do
      # override `context`
      let(:context) {
        { current_user: User.new(name: "ABC") }
      }
      it "shows the user's name" do
        user_name = result["data"]["viewer"]["name"]
        expect(user_name).to eq("ABC")
      end
    end
  end
end
```
