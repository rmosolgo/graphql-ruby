---
title: Schema — Types and Fields
---

Types, fields and arguments make up a schema's type system. These objects are also open to extension via `metadata` and `accepts_definitions`.

## Types

Types describe objects and values in a system. The API documentation for each type contains a detailed description with examples.

Objects are described with {{ "GraphQL::ObjectType" | api_doc }}s.

Scalar values are described with built-in scalars (string, int, float, boolean, ID) or custom {{ "GraphQL::EnumType" | api_doc }}s. You can define custom {{ "GraphQL::ScalarType" | api_doc }}s, too.

Scalars and enums can be sent to GraphQL as inputs. For complex inputs (key-value pairs), use {{ "GraphQL::InputObjectType" | api_doc }}.

There are two abstract types, too:

- {{ "GraphQL::InterfaceType" | api_doc }} describes a collection of object types which implement some of the same fields.
- {{ "GraphQL::UnionType" | api_doc }} describes a collection of object types which may appear in the same place in the schema (ie, may be returned by the same field.)


{{ "GraphQL::ListType" | api_doc }} and {{ "GraphQL::NonNullType" | api_doc }} modify other types, describing them as "list of _T_" or "required _T_".

### Referencing Types

Some parts of schema definition take types as an input. There are two good ways to provide types:

1. __By value__. Pass a variable which holds the type.

   ```ruby
   # constant
   field :team, TeamType
   # local variable
   field :stadium, stadium_type
   ```

2. __By proc__, which will be lazy-evaluated to look up a type.

   ```ruby
   field :team, -> { TeamType }
   field :stadium, -> { LookupTypeForModel.lookup(Stadium) }
   ```


## Fields

{{ "GraphQL::ObjectType" | api_doc }}s and {{ "GraphQL::InterfaceType" | api_doc }}s may expose their values with _fields_. A field definition looks like this:

```ruby
PostType = GraphQL::ObjectType.define do
  # ...
  #     name  , type        , description (optional)
  field :title, types.String, "The title of the Post"
end
```

By default, fields are resolved by sending the name to the underlying object (eg `post.title` in the example above).

You can define a different resolution by providing a `resolve` function:

```ruby
PostType = GraphQL::ObjectType.define do
  # ...
  #     name   , type        , description (optional)
  field :teaser, types.String, "The teaser of the Post" do
    # how to get the value?
    resolve ->(obj, args, ctx) {
      # first 40 chars of the body
      obj.body[0, 40]
    }
  end
end
```

The resolve function receives inputs:

- `object`: The underlying object for this type (above, a `Post` instance)
- `arguments`: The arguments for this field (see below, a {{ "GraphQL::Query::Arguments" | api_doc }} instance)
- `context`: The context for this query (see ["Executing Queries"]({{ site.baseurl }}/queries/executing_queries), a {{ "GraphQL::Query::Context" | api_doc }} instance)

In fact, the `field do ... end` block is passed to {{ "GraphQL::Field" | api_doc }}'s `.define` method, so you can define many things there:

```ruby
field do
  name "teaser"
  type types.String
  description "..."
  resolve ->(obj, args, ctx) { ... }
  deprecation_reason "Too long, use .title instead"
  complexity 2
end
```

## Arguments

Fields can take __arguments__ as input. These can be used to determine the return value (eg, filtering search results) or to modify the application state (eg, updating the database in `MutationType`).

Arguments are defined with the `argument` helper:

```ruby
field :search_posts, types[PostType] do
  argument :category, types.String
  resolve ->(obj, args, ctx) {
    args[:category]
    # => maybe a string, eg "Programming"
    if args[:category]
      Post.where(category: category).limit(10)
    else
      Post.all.limit(10)
    end
  }
end
```

Use `!` to mark an argument as _required_:

```ruby
# This argument is a required string:
argument :category, !types.String
```

Only certain types are valid for arguments:

- {{ "GraphQL::ScalarType" | api_doc }}, including built-in scalars (string, int, float, boolean, ID)
- {{ "GraphQL::EnumType" | api_doc }}
- {{ "GraphQL::InputObjectType" | api_doc }}, which allows key-value pairs as input
- {{ "GraphQL::ListType" | api_doc }}s of a valid input type
- {{ "GraphQL::NonNullType" | api_doc }}s of a valid input type


The `args` parameter of a `resolve` function will always be a {{ "GraphQL::Query::Arguments" | api_doc }}. You can access specific arguments with `["arg_name"]` or `[:arg_name]`. You recursively turn it into a Ruby Hash with `to_h`. Inside `args`, scalars will be parsed into Ruby values and enums will be converted to their `value:` (if one was provided).

```ruby
resolve ->(obj, args, ctx) {
  args["category"] == args[:category]
  # => true
  args.to_h
  # => { "category" => "Programming" }
  # ...
}
```

## Extending type and field definitions

Types, fields, and arguments have a `metadata` hash which accepts values during definition.

First, make a custom definition:

```ruby
GraphQL::ObjectType.accepts_definitions resolves_to_class_names: GraphQL::Define.assign_metadata_key(:resolves_to_class_names)
# or:
# GraphQL::Field.accepts_definitions(...)
# GraphQL::Argument.accepts_definitions(...)

MySchema = GraphQL::Schema.define do
  # ...
end
```


Then, use the custom definition:

```ruby
Post = GraphQL::ObjectType.define do
  # ...
  resolves_to_class_names ["Post", "StaffUpdate"]
end
```

Access `type.metadata` later:

```ruby
MySchema = GraphQL::Schema.define do
  # ...
  # Use the type's declared `resolves_to_class_names`
  # to figure out if `obj` is a member of that type
  resolve_type ->(obj, ctx) {
    class_name = obj.class.name
    MySchema.types.values.find { |type| type.metadata[:resolves_to_class_names].include?(class_name) }
  }
end
```

This behavior is provided by {{ "GraphQL::Define::InstanceDefinable" | api_doc }}.
