---
title: GraphQL::Relay
---

Since version `0.18.0`, `GraphQL::Relay` provides several helpers for making a Relay-compliant GraphQL endpoint in Ruby:

- [global ids](#global-ids) support Relay's UUID-based refetching
- [connections](#connections) implement Relay's pagination
- [mutations](#mutations) allow Relay to mutate your system predictably


## Global Ids

Global ids (or UUIDs) support two features in Relay:

- __Caching__: Unique IDs are used as primary keys in Relay's client-side cache.
- __Refetching__: Relay uses unique IDs to refetch objects when it determines that its cache is stale. (It uses the `Query.node` field to refetch objects.)

### Defining UUIDs

You must provide a function for generating UUIDs and fetching objects with them. In your schema, define `id_from_object` and `object_from_id`:

```ruby
MySchema = GraphQL::Schema.define do
  id_from_object ->(object, type_definition, query_ctx) {
    # Call your application's UUID method here
    # It should return a string
    MyApp::GlobalId.encrypt(object.class.name, object.id)
  }

  object_from_id ->(id, query_ctx) {
    class_name, item_id = MyApp::GlobalId.decrypt(id)
    # "Post" => Post.find(id)
    Object.const_get(class_name).find(item_id)
  }
end
```

An unencrypted ID generator is provided in the gem. It uses `Base64` to encode values. You can use it like this:

```ruby
MySchema = GraphQL::Schema.define do
  # Create UUIDs by joining the type name & ID, then base64-encoding it
  id_from_object ->(object, type_definition, query_ctx) {
    GraphQL::Schema::UniqueWithinType.encode(type_definition.name, object.id)
  }

  object_from_id ->(id, query_ctx) {
    type_name, item_id = GraphQL::Schema::UniqueWithinType.decode(id)
    # Now, based on `type_name` and `id`
    # find an object in your application
    # ....
  }
end
```

### UUID fields

To participate in Relay's caching and refetching, objects must do two things:

- Implement the `"Node"` interface
- Define an `"id"` field which returns a UUID

To implement the node interface, include `GraphQL::Relay::Node.interface` in your list of interfaces:

```ruby
PostType = GraphQL::ObjectType.define do
  name "Post"
  # Implement the "Node" interface for Relay
  interfaces [GraphQL::Relay::Node.interface]
  # ...
end
```

To add a UUID field named `"id"`, use the `global_id_field` helper:

```ruby
PostType = GraphQL::ObjectType.define do
  name "Post"
  # ...
  # `id` exposes the UUID
  global_id_field :id
  # ...
end
```

Now, `PostType` can participate in Relay's UUID-based features.

### `node` field (find-by-UUID)

You should also provide a root-level `node` field so that Relay can refetch objects from your schema. It is provided as `GraphQL::Relay::Node.field`, so you can attach it like this:

```ruby
QueryType = GraphQL::ObjectType.define do
  name "Query"
  # Used by Relay to lookup objects by UUID:
  field :node, GraphQL::Relay::Node.field
  # ...
end
```

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
  resolve ->(post, args, ctx) {
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
    resolve ->(obj, args, ctx) { obj.object.count }
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

### Connection objects

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
items = [...]     # your AR or sequel collection objects
args = {}         # stub out arguments for this connection object
items_connection = GraphQL::Relay::RelationConnection.new(
  items,
  args
)
edge = GraphQL::Relay::Edge.new(object, items_connection)
```

Additionally, connections may be provided with the GraphQL::Field that created them. This may be used for custom introspection or instrumentation. For example,

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
MySchema = GraphQL::Schema.define do
  query QueryType,
  mutation MutationType
end
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
  - `resolve(->(obj, inputs, ctx) { ... })`, the mutation which will actually happen


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
  # `object` is the `root_value:` passed to `Schema.execute`.
  resolve ->(object, inputs, ctx) {
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
  - Takes `obj`, which is the `root_value:` provided to `Schema.execute`
  - Takes `inputs`, which is a hash whose keys are the ones defined by `input_field`
  - Takes `ctx`, which is the query context you passed with the `context:` keyword
  - Must return a hash with keys matching your defined `return_field`s (unless you provide a `return_type`, see below)

### Specify a Return Type

Instead of specifying `return_field`s, you can specify a `return_type` for a mutation. This type will be used to expose the object returned from `resolve`.

```ruby
CreateUser = GraphQL::Relay::Mutation.define do
  return_type UserMutationResultType
  # ...
  resolve ->(obj, input, ctx) {
    user = User.create(input)
    # this object will be treated as `UserMutationResultType`
    UserMutationResult.new(user, client_mutation_id: input[:clientMutationId])
  }
end
```

If you provide your own return type, it's up to you to support `clientMutationId`
