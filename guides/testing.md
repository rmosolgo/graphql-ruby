---
title: Testing a GraphQL Schema
---

There are a few ways to test the behavior of your GraphQL schema:

- _Don't_ test the schema, test other objects instead
- Test schema elements (types, fields) in isolation
- Execute GraphQL queries and test the result


## Don't test the schema

The easiest way to test behavior of a GraphQL schema is to extract behavior into separate objects and test those objects in isolation. For Rails, you don't test your models by running controller tests, right? Similarly, you can test "lower-level" parts of the system on their own without running end-to-end tests.

For example, consider a field which calculates its own value:

```ruby
PostType = GraphQL::ObjectType.define do
  # ...
  field :isTrending, types.Boolean do
    resolve ->(obj, args, ctx) {
      recent_comments = comments.where("created_at < ?", 1.day.ago)
      recent_comments.count > 100
    }
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

PostType = GraphQL::ObjectType.define do
  # ...
  field :isTrending, types.Boolean do
    resolve ->(obj, args, ctx) {
      # Use the Post::Trending class to calculate the value
      Post::Trending.new(obj).value
    }
  end
end
```

This is an improvement because your behavior is not coupled to your GraphQL schema. Besides that, it's easier to test: you can simply unit test the calculation class. For example:

```ruby
# app/models/post/trending_spec.rb
describe Post::Trending do
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

## Testing schema elements in isolation

You can access type and field objects from your schema to make sure they're defined correctly and behave the way you expect them to.

#### Types

Access a type by name from the schema with `GraphQL::Schema#types`:

```ruby
post = MySchema.types["Post"] # => PostType
post.fields                   # => {"id" => <GraphQL::Field>, ... }
post.fields.keys              # => ["id", "title", "body", "author", "comments"]
```

The returned value is an instance of the type class you used to `.define` it (eg, `GraphQL::ObjectType`, `GraphQL::EnumType`, `GraphQL::InputObjectType`).

#### Fields

You can get a type's fields from the `GraphQL::ObjectType#fields` hash. For example:

```ruby
post_type = MySchema.types["Post"]
title_field = post_type.fields["title"] #=> <GraphQL::Field>
title_field.name #=> "title"
```

You can test a resolve function by calling `GraphQL::Field#resolve`:

```ruby
# Because this field doesn't use context or variables, simply pass `nil`
post = Post.new(title: "Welcome to my blog")
name_field.resolve(post, nil, nil) #=> "Welcome to my blog"
```

Calling `resolve` in this way does _not_ apply any coercion. (That's only applied during query execution.)

#### Other elements

Similarly, you can access:

- `GraphQL::Field#arguments`, which are `String` => `GraphQL::Argument` pairs
- `GraphQL::Field#type`, the field's return type
- `GraphQL::InputObjectType#arguments`, which are `String` => `GraphQL::Argument` pairs
- `GraphQL::EnumType#values`, which are `String` => `GraphQL::EnumType::EnumValue` pairs
- `GraphQL::InterfaceType#possible_types` and `GraphQL::UnionType#possible_types`, which are lists of types.

`GraphQL::BaseType#unwrap` may also be helpful. It returns the "inner-most" type. For example:

```ruby
required_list_of_strings = GraphQL::NonNullType.new(
  of_type: GraphQL::ListType.new(
    of_type: GraphQL::STRING_TYPE
  )
)

required_list_of_strings.unwrap #=> GraphQL::STRING_TYPE
```

## Executing GraphQL queries

Sometimes, you really need an end-to-end test. Although it requires a lot of overhead, it's nice to have a "sanity check" on the system as a whole.

You can execute queries on your schema in a test. For example, you can set it up like this:

```ruby
describe MySchema do
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
        current_user: User.new(name: "ABC")
      }

      it "shows the user's name" do
        user_name = result["data"]["viewer"]["name"]
        expect(user_name).to eq("ABC")
      end
    end
  end
end
```
