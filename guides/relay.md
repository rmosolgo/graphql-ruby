# GraphQL::Relay

## `graphql-relay` gem

__Note__: For graphql versions `< 0.18`, you must include:

```
gem "graphql-relay"
```

Starting in `0.18`, `GraphQL::Relay` is part of `graphql`.

------------------------------

`GraphQL::Relay` provides several helpers for making a Relay-compliant GraphQL endpoint in Ruby:

- [global ids](#global-ids) support Relay's UUID-based refetching
- [connections](#connections) implement Relay's pagination
- [mutations](#mutations) allow Relay to mutate your system predictably


## Global Ids

Global ids (or UUIDs) provide refetching & global identification for Relay.

### UUID Lookup

Use `GraphQL::Relay::GlobalNodeIdentification` helper by defining `object_from_id(global_id, ctx)` & `type_from_object(object)`. Then, assign the result to `Schema#node_identification` so that it can be used for query execution.

For example, define a node identification helper:


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

Then assign it to the schema:

```ruby
MySchema = GraphQL::Schema.new(...)
# Assign your node identification helper:
MySchema.node_identification = NodeIdentification
```

### UUID fields

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

### `node` field (find-by-UUID)

You should also add a field to your root query type for Relay to re-fetch objects:

```ruby
QueryType = GraphQL::ObjectType.define do
  name "Query"
  # Used by Relay to lookup objects by UUID:
  field :node, field: NodeIdentification.field

  # ...
end
```

### Custom UUID Generation

By default, `GraphQL::Relay` uses `Base64.strict_encode64` to generate opaque global ids. You can modify this behavior by providing two configurations. They work together to encode and decode ids:

```ruby
NodeIdentification = GraphQL::Relay::GlobalNodeIdentification.define do
  # ...

  # Return a string for re-fetching this object
  to_global_id -> (type_name, id) {
    "#{type_name}/#{id}"
  }

  # Based on the incoming string, extract the type_name and id
  from_global_id -> (global_id) {
    id_parts  = global_id.split("/")
    type_name = id_parts[0]
    id        = id_parts[1]
    # Return *both*:
    [type_name, id]
  }
end

# ...

MySchema.node_identification = NodeIdentification
```

`GraphQL::Relay` will use those procs for interacting with global ids.

## Connections

Connections provide pagination and `pageInfo` for `Array`s,  `ActiveRecord::Relation`s or `Sequel::Dataset`s.

### Connection fields

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
  # Use a name to disambiguate this from `CommentType.connection_type`
  name "CommentConnectionWithSince"

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

### Maximum Page Size

You can limit the number of results with `max_page_size:`:

```ruby
connection :featured_comments, CommentType.connection_type, max_page_size: 50
```

### Connection types

You can customize a connection type with `.define_connection`:

```ruby
PostConnectionWithTotalCountType = PostType.define_connection do
  field :totalCount do
    type types.Int
    # `obj` is the Connection, `obj.object` is the collection of Posts
    resolve -> (obj, args, ctx) { obj.object.count }
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

### Custom edge types

If you need custom fields on `edge`s, you can define an edge type and pass it to a connection:

```ruby
# Person => Membership => Team
MembershipSinceEdgeType = BaseType.define_edge do
  name "MembershipSinceEdge"
  field :memberSince, types.Int, "The date that this person joined this team" do
    resolve -> (obj, args, ctx) {
      obj # => GraphQL::Relay::Edge instnce
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
  field :isPrimary, types.Boolean, "Is this person the team leader?". property: :primary?
  end
end

TeamMembershipsConnectionType = TeamType.define_connection(
    edge_class: MembershipSinceEdge,
    edge_type: MembershipSinceEdgeType,
  ) do
  # Use a name so it doesn't conflict with "TeamConnection"
  name "TeamMembershipsConnection"
end
```

### Connection objects

Maybe you need to make a connection object yourself (for example, to return a connection type from a mutation). You can create a connection object like this:

```ruby
items = [...]     # your collection objects
args = {}         # stub out arguments for this connection object
connection_class = GraphQL::Relay::BaseConnection.connection_for_nodes(items)
connection_class.new(items, args)
```

`.connection_for_nodes` will return RelationConnection or ArrayConnection depending on `items`, then you can make a new connection

### Custom connections

You can define a custom connection class and add it to `GraphQL::Relay`.

First, define the custom connection:

```ruby
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

## Mutations

Mutations allow Relay to mutate your system. They conform to a strict API which makes them predictable to the client.

## Mutation root

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

## Mutation fields

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

## Relay mutations

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
