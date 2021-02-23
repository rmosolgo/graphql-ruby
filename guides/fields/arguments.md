---
layout: guide
doc_stub: false
search: true
section: Fields
title: Arguments
desc: Fields may take arguments as inputs
index: 1
---

Fields can take **arguments** as input. These can be used to determine the return value (eg, filtering search results) or to modify the application state (eg, updating the database in `MutationType`).

Arguments are defined with the `argument` helper. These arguments are passed as [keyword arguments](https://robots.thoughtbot.com/ruby-2-keyword-arguments) to the resolver method:

```ruby
field :search_posts, [PostType], null: false do
  argument :category, String, required: true
end

def search_posts(category:)
  Post.where(category: category).limit(10)
end
```

To make an argument optional, set `required: false`, and set default values for the corresponding keyword arguments:

```ruby
field :search_posts, [PostType], null: false do
  argument :category, String, required: false
end

def search_posts(category: nil)
  if category
    Post.where(category: category).limit(10)
  else
    Post.all.limit(10)
  end
end
```

Be aware that if all arguments are optional and the query does not provide any arguments, then the resolver method will be called with no arguments. To prevent an `ArgumentError` in this case, you must either specify default values for all keyword arguments (as done in the prior example) or use the double splat operator argument in the method definition. For example:

```ruby
def search_posts(**args)
  if args[:category]
    Post.where(category: args[:category]).limit(10)
  else
    Post.all.limit(10)
  end
end
```

Another approach is to use `default_value: value` to provide a default value for the argument if it is not supplied in the query.

```ruby
field :search_posts, [PostType], null: false do
  argument :category, String, required: false, default_value: "Programming"
end

def search_posts(category:)
  Post.where(category: category).limit(10)
end
```

**Experimental:** __Deprecated__ arguments can be marked by adding a `deprecation_reason:` keyword argument:

```ruby
field :search_posts, [PostType], null: false do
  argument :name, String, required: false, deprecation_reason: "Use `query` instead."
  argument :query, String, required: false
end
```
Note argument deprecation is a stage 2 GraphQL [proposal](https://github.com/graphql/graphql-spec/pull/525) so not all clients will leverage this information.

Use `as: :alternate_name` to use a different key from within your resolvers while
exposing another key to clients.

```ruby
field :post, PostType, null: false do
  argument :post_id, ID, required: true, as: :id
end

def post(id:)
  Post.find(id)
end
```

Provide a `prepare` function to modify or validate the value of an argument before the field's resolver method is executed:

```ruby
field :posts, [PostType], null: false do
  argument :start_date, String, required: true, prepare: ->(startDate, ctx) {
    # return the prepared argument.
    # raise a GraphQL::ExecutionError to halt the execution of the field and
    # add the exception's message to the `errors` key.
  }
end

def posts(start_date:)
  # use prepared start_date
end
```

Arguments that are snake_cased will be camelized in the GraphQL schema. Using the example of:

```ruby
field :posts, [PostType], null: false do
  argument :start_year, Int, required: true
end
```

The corresponding GraphQL query will look like:

```graphql
{
  posts(startYear: 2018) {
    id
  }
}
```

To disable auto-camelization, pass `camelize: false` to the `argument` method.

```ruby
field :posts, [PostType], null: false do
  argument :start_year, Int, required: true, camelize: false
end
```

Furthermore, if your argument is already camelCased, then it will remain camelized in the GraphQL schema. However, the argument will be converted to snake_case when it is passed to the resolver method:

```ruby
field :posts, [PostType], null: false do
  argument :startYear, Int, required: true
end

def posts(start_year:)
  # ...
end
```

Only certain types are valid for arguments:

- {{ "GraphQL::ScalarType" | api_doc }}, including built-in scalars (string, int, float, boolean, ID)
- {{ "GraphQL::EnumType" | api_doc }}
- {{ "GraphQL::InputObjectType" | api_doc }}, which allows key-value pairs as input
- {{ "GraphQL::ListType" | api_doc }}s of a valid input type
- {{ "GraphQL::NonNullType" | api_doc }}s of a valid input type
