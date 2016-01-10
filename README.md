# graphql-relay

[![Gem Version](https://badge.fury.io/rb/graphql-relay.svg)](http://badge.fury.io/rb/graphql-relay)
[![Build Status](https://travis-ci.org/rmosolgo/graphql-relay-ruby.svg?branch=master)](https://travis-ci.org/rmosolgo/graphql-relay-ruby)
[![Code Climate](https://codeclimate.com/github/rmosolgo/graphql-relay-ruby/badges/gpa.svg)](https://codeclimate.com/github/rmosolgo/graphql-relay-ruby)
[![Test Coverage](https://codeclimate.com/github/rmosolgo/graphql-relay-ruby/badges/coverage.svg)](https://codeclimate.com/github/rmosolgo/graphql-relay-ruby/coverage)

Helpers for using [`graphql`](https://github.com/rmosolgo/graphql-ruby) with Relay.

[API Documentation](http://www.rubydoc.info/github/rmosolgo/graphql-relay-ruby)
## Installation

```ruby
gem "graphql-relay"
```

```
bundle install
```

## Usage

`graphql-relay` provides several helpers for making a Relay-compliant GraphQL endpoint in Ruby:

- [global ids](#global-ids) support Relay's UUID-based refetching
- [connections](#connections) implement Relay's pagination
- [mutations](#mutations) allow Relay to mutate your system predictably


### Global Ids

Global ids (or UUIDs) provide refetching & global identification for Relay.

#### UUID Lookup

Use `GraphQL::Relay::GlobalNodeIdentification` helper by defining `object_from_id(global_id, ctx)` & `type_from_object(object)`. The resulting `NodeIdentification` object is in your schema _and_ internally by `GraphQL::Relay`.


```ruby
NodeIdentification = GraphQL::Relay::GlobalNodeIdentification.define do
  # Given a UUID & the query context,
  # return the corresponding application object
  object_from_id -> (id, ctx) do
    type_name, id = NodeIdentification.from_global_id(id)
    # "Post" -> Post.find(id)
    Object.const_get(type_name).find(id)
  end

  # Given an application object,
  # return a GraphQL ObjectType to expose that object
  type_from_object -> (object) do
    if object.is_a?(Post)
      PostType
    else
      CommentType
    end
  end
end
```

#### UUID fields

ObjectTypes in your schema should implement `NodeIdentification.interface` with the `global_id_field` helper, for example:

```ruby
PostType = GraphQL::ObjectType.define do
  name "Post"
  interfaces [NodeIdentification.interface]
  # `id` exposes the UUID
  global_id_field :id

  # ...
end
```

#### `node` field (find-by-UUID)

You should also add a field to your root query type for Relay to re-fetch objects:

```ruby
QueryType = GraphQL::ObjectType.define do
  name "Query"
  # Used by Relay to lookup objects by UUID:
  field :node, field: NodeIdentification.field

  # ...
end
```

### Connections

Connections provide pagination and `pageInfo` for `Array`s or `ActiveRecord::Relation`s.

#### Connection fields

To define a connection field, use the `connection` helper. For a return type, get a type's `.connection_type`. For example:

```ruby
PostType = GraphQL::ObjectType.define do
  # `comments` field returns a CommentsConnection:
  connection :comments, CommentType.connection_type
  # To avoid circular dependencies, wrap the return type in a proc:
  connection :similarPosts, -> { PostType.connection_type }

  # ...
end
```

You can also define custom arguments and a custom resolve function for connections, just like other fields:

```ruby
connection :featured_comments, CommentType.connection_type do
  # Add an argument:
  argument :since, types.String

  # Return an Array or ActiveRecord::Relation
  resolve -> (post, args, ctx) {
    comments = post.comments.featured

    if args[:since]
      comments = comments.where("created_at >= ", since)
    end

    comments
  }
end
```

#### Connection types

You can customize a connection type with `.define_connection`:

```ruby
PostType.define_connection do
  field :totalCount do
    type types.Int
    # `obj` is the Connection, `obj.object` is the collection of Posts
    resolve -> (obj, args, ctx) { obj.object.count }
  end
end
```

Now, `PostType.connection_type` will include a `totalCount` field.

#### Connection objects

Maybe you need to make a connection object yourself (for example, to return a connection type from a mutation). You can create a connection object like this:

```
items = ...   # your collection objects
args = {}     # stub out arguments for this connection object
connection_class = GraphQL::Relay::BaseConnection.connection_for_items(items)
connection_class.new(items, args)
```

`.connection_for_items` will return RelationConnection or ArrayConnection depending on `items`, then you can make a new connection

#### Custom connections

You can define a custom connection class and add it to `GraphQL::Relay`.

First, define the custom connection:

```ruby
class SetConnection < BaseConnection
  # derive a cursor from `item`
  # (it is used to find next & previous nodes,
  # so it should include `order`)
  def cursor_from_node(item)
    # ...
  end

  private
  # apply `#first` & `#last` to limit results
  def paged_nodes
    # ...
  end

  # apply cursor, order, filters, etc
  # to get a subset of matching objects
  def sliced_nodes
    # ...
  end
end
```

Then, register the new connection with `GraphQL::Relay::BaseConnection`:

```ruby
# When exposing a `Set`, use `SetConnection`:
GraphQL::Relay::BaseConnection.register_connection_implementation(Set, SetConnection)
```

At runtime, `GraphQL::Relay` will use `SetConnection` to expose `Set`s.

#### Creating connection fields by hand

If you need lower-level access to Connection fields, you can create them programmatically. Given a `GraphQL::Field` which returns a collection of items, you can turn it into a connection field with `ConnectionField.create`.

For example, to wrap a field with a connection field:

```ruby
field = GraphQL::Field.new
# ... define the field
connection_field = GraphQL::Relay::ConnectionField.create(field)
```


### Mutations

Mutations allow Relay to mutate your system. They conform to a strict API which makes them predictable to the client.

### Mutation root

To add mutations to your GraphQL schema, define a mutation type and pass it to your schema:

```ruby
# Define the mutation type
MutationType = GraphQL::ObjectType.define do
  name "Mutation"
  # ...
end

# and pass it to the schema
MySchema = GraphQL::Schema.new(
  query: QueryType,
  mutation: MutationType
)
```

Like `QueryType`, `MutationType` is a root of the schema.

### Mutation fields

Members of `MutationType` are _mutation fields_. For GraphQL in general, mutation fields are identical to query fields _except_ that they have side-effects (which mutate application state, eg, update the database).

For Relay-compliant GraphQL, a mutation field must comply to a strict API. `GraphQL::Relay` includes a mutation definition helper (see below) to make it simple.

After defining a mutation (see below), add it to your mutation type:

```ruby
MutationType = GraphQL::ObjectType.define do
  name "Mutation"
  # Add the mutation's derived field to the mutation type
  field :addComment, field: AddCommentMutation.field
  # ...
end
```

### Relay mutations

To define a mutation, use `GraphQL::Relay::Mutation.define`. Inside the block, you should configure:
  - `name`, which will name the mutation field & derived types
  - `input_field`s, which will be applied to the derived `InputObjectType`
  - `return_field`s, which will be applied to the derived `ObjectType`
  - `resolve(-> (inputs, ctx) { ... })`, the mutation which will actually happen


For example:

```ruby
AddCommentMutation = GraphQL::Relay::Mutation.define do
  # Used to name derived types:
  name "AddComment"

  # Accessible from `input` in the resolve function:
  input_field :postId, !types.ID
  input_field :authorId, !types.ID
  input_field :content, !types.String

  # The result has access to these fields,
  # resolve must return a hash with these keys
  return_field :post, PostType
  return_field :comment, CommentType

  # The resolve proc is where you alter the system state.
  resolve -> (inputs, ctx) {
    post = Post.find(inputs[:postId])
    comment = post.comments.create!(author_id: inputs[:authorId], content: inputs[:content])

    {comment: comment, post: post}
  }
end


```

Under the hood, GraphQL creates:
  - A field for your schema's `mutation` root
  - A derived `InputObjectType` for input values
  - A derived `ObjectType` for return values

The resolve proc:
  - Takes `inputs`, which is a hash whose keys are the ones defined by `input_field`
  - Takes `ctx`, which is the query context you passed with the `context:` keyword
  - Must return a hash with keys matching your defined `return_field`s

## Getting Started Tutorials

#### Series: Building a blog in GraphQL and Relay on Rails
1. **Introduction:** https://medium.com/@gauravtiwari/graphql-and-relay-on-rails-getting-started-955a49d251de
2. **Part1:** https://medium.com/@gauravtiwari/graphql-and-relay-on-rails-creating-types-and-schema-b3f9b232ccfc
3. **Part2:**
https://medium.com/@gauravtiwari/graphql-and-relay-on-rails-first-relay-powered-react-component-cb3f9ee95eca

#### Tutorials
1. https://medium.com/@khor/relay-facebook-on-rails-8b4af2057152
2. http://mgiroux.me/2015/getting-started-with-rails-graphql-relay/
3. http://mgiroux.me/2015/uploading-files-using-relay-with-rails/

## Todo

- Add a `max_page_size` config for connections?
- Refactor some RelationConnection issues:
  - fix [unbounded count in page info](https://github.com/rmosolgo/graphql-relay-ruby/blob/88b3d94f75a6dd4c8b2604743108db31f66f8dcc/lib/graphql/relay/base_connection.rb#L79-L86), [details](https://github.com/rmosolgo/graphql-relay-ruby/issues/1)

## More Resources

- [GraphQL Slack](http://graphql-slack.herokuapp.com), come join us in the `#ruby` channel!
- [`graphql`](https://github.com/rmosolgo/graphql-ruby) Ruby gem
- [`graphql-relay-js`](https://github.com/graphql/graphql-relay-js) JavaScript helpers for GraphQL and Relay
