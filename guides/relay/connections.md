---
layout: guide
search: true
title: Connections
section: Relay
desc: Build and customize Relay-style connection types
index: 1
---

Relay expresses [one-to-many relationships with _connections_](https://facebook.github.io/relay/graphql/connections.htm). Connections support pagination, filtering and metadata in a robust way.

`graphql-ruby` includes built-in connection support for `Array`, `ActiveRecord::Relation`s, and `Sequel::Dataset`s. You can define custom connection classes to expose other collections with GraphQL.

## Connection fields

To define a connection field, use the `connection` helper. For a return type, get a type's `.connection_type`.  The `resolve` proc should return a collection (eg, `Array` or `ActiveRecord::Relation`) _without_ pagination. (The connection will paginate the collection).

For example:

```ruby
PostType = GraphQL::ObjectType.define do
  # `Post#comments` returns an ActiveRecord::Relation
  # The GraphQL field returns a Connection
  connection :comments, CommentType.connection_type
  # `Post#similar_posts` returns an Array
  connection :similarPosts, PostType.connection_type, property: :similar_posts

  # ...
end
```

You can also define custom arguments and a custom resolve function for connections, just like other fields:

```ruby
connection :featured_comments, CommentType.connection_type do
  # Add an argument:
  argument :since, types.String

  # Return an Array or ActiveRecord::Relation
  resolve ->(post, args, ctx) {
    comments = post.comments.featured

    if args[:since]
      comments = comments.where("created_at >= ", args[:since])
    end

    comments
  }
end
```

### Maximum Page Size

You can limit the number of results with `max_page_size:`:

```ruby
connection :featured_comments, CommentType.connection_type, max_page_size: 50
```

In addition, you can set a global default for all connection that do not specify a `max_page_size`:

```ruby
MySchema = GraphQL::Schema.define do
  default_max_page_size 100
end
```

## Connection types

You can customize a connection type with `.define_connection`:

```ruby
# Make a customized connection type
PostConnectionWithTotalCountType = PostType.define_connection do
  name "PostConnectionWithTotalCount"
  field :totalCount do
    type types.Int
    # - `obj` is the Connection
    # - `obj.nodes` is the collection of Posts
    resolve ->(obj, args, ctx) { obj.nodes.size }
  end
end

```

Now, you can use `PostConnectionWithTotalCountType` to define a connection with the "totalCount" field:

```ruby
AuthorType = GraphQL::ObjectType.define do
  # Use the custom connection type:
  connection :posts, PostConnectionWithTotalCountType
end
```

This way, you can query your custom fields, for example:

```graphql
{
  author(id: 1) {
    posts {
      totalCount    # <= Your custom field
    }
  }
}
```

### Custom edge types

If you need custom fields on `edge`s, you can define an edge type and pass it to a connection:

```ruby
# Person => Membership => Team
MembershipSinceEdgeType = TeamType.define_edge do
  name "MembershipSinceEdge"
  field :memberSince, types.Int, "The date that this person joined this team" do
    resolve ->(obj, args, ctx) {
      obj # => GraphQL::Relay::Edge instance
      person = obj.parent
      team = obj.node
      membership = Membership.where(person: person, team: team).first
      membership.created_at.to_i
    }
  end
end
```

Then, pass the edge type when defining the connection type:

```ruby
TeamMembershipsConnectionType = TeamType.define_connection(edge_type: MembershipSinceEdgeType) do
  # Use a name so it doesn't conflict with "TeamConnection"
  name "TeamMembershipsConnection"
end
```

Now, you can query custom fields on the `edge`:

```graphql
{
  me {
    teams {
      edge {
        memberSince     # <= Here's your custom field
        node {
          teamName: name
        }
      }
    }
  }
}
```

### Custom Edge classes

For more robust custom edges, you can define a custom edge class. It will be `obj` in the edge type's resolve function. For example, to define a membership edge:

```ruby
# Make sure to familiarize yourself with GraphQL::Relay::Edge --
# you have to avoid naming conflicts here!
class MembershipSinceEdge < GraphQL::Relay::Edge
  # Cache `membership` to avoid multiple DB queries
  def membership
    @membership ||= begin
      # "parent" and "node" are passed in from the surrounding Connection,
      # See `Edge#initialize` for details
      person = self.parent
      team = self.node
      Membership.where(person: person, team: team).first
    end
  end

  def member_since
    membership.created_at.to_i
  end

  def leader?
    membership.leader?
  end
end
```

Then, hook it up with custom edge type and custom connection type:

```ruby
# Person => Membership => Team
MembershipSinceEdgeType = BaseType.define_edge do
  name "MembershipSinceEdge"
  field :memberSince, types.Int, "The date that this person joined this team", property: :member_since
  field :isPrimary, types.Boolean, "Is this person the team leader?", property: :primary?
end

TeamMembershipsConnectionType = TeamType.define_connection(
    edge_class: MembershipSinceEdge,
    edge_type: MembershipSinceEdgeType,
  ) do
  # Use a name so it doesn't conflict with "TeamConnection"
  name "TeamMembershipsConnection"
end
```

## Connection objects

Maybe you need to make a connection object yourself (for example, to return a connection type from a mutation). You can create a connection object like this:

```ruby
items = [...]     # your collection objects
args = {}         # stub out arguments for this connection object
connection_class = GraphQL::Relay::BaseConnection.connection_for_nodes(items)
connection_class.new(items, args)
```

`.connection_for_nodes` will return RelationConnection or ArrayConnection depending on `items`, then you can make a new connection

For specifying a connection based on an `ActiveRecord::Relation` or `Sequel::Dataset`:

```ruby
object = {}       # your newly created object
items = [...]     # your AR or Sequel collection
args = {}         # stub out arguments for this connection object
items_connection = GraphQL::Relay::RelationConnection.new(
  items,
  args
)
edge = GraphQL::Relay::Edge.new(object, items_connection)
```

Additionally, connections may be provided with the `GraphQL::Field` that created them. This may be used for custom introspection or instrumentation. For example,

```ruby
  Schema.get_field(TodoListType, "todos")
  # => #<GraphQL::Field name="todos">
  context.irep_node.definitions[TodoListType]
  # => #<GraphQL::Field name="todos">
  # although this one may not work with fields on interfaces
```

### Custom connections

You can define a custom connection class and add it to `GraphQL::Relay`.

First, define the custom connection:

```ruby
require "set" # From Ruby's standard library
class SetConnection < BaseConnection
  # derive a cursor from `item`
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

### Creating connection fields by hand

If you need lower-level access to Connection fields, you can create them programmatically. Given a `GraphQL::Field` which returns a collection of items, you can turn it into a connection field with `ConnectionField.create`.

For example, to wrap a field with a connection field:

```ruby
field = GraphQL::Field.new
# ... define the field
connection_field = GraphQL::Relay::ConnectionField.create(field)
```

## Cursors

By default, cursors are encoded in base64 to make them opaque to a human client. You can specify a custom encoder with `Schema#cursor_encoder`. The value should be an object which responds to `.encode(plain_text, nonce:)` and `.decode(encoded_text, nonce: false)`.

For example, to use URL-safe base-64 encoding:

```ruby
module URLSafeBase64Encoder
  def self.encode(txt, nonce: false)
    Base64.urlsafe_encode64(txt)
  end

  def self.decode(txt, nonce: false)
    Base64.urlsafe_decode64(txt)
  end
end

MySchema = GraphQL::Schema.define do
  # ...
  cursor_encoder(URLSafeBase64Encoder)
end
```

Now, all connections will use URL-safe base-64 encoding.

From a connection instance, the `cursor_encoders` methods available via {{ "GraphQL::Relay::BaseConnection#encode" | api_doc }} and {{ "GraphQL::Relay::BaseConnection#decode" | api_doc }}
