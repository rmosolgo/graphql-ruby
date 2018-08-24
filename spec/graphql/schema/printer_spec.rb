# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Printer do
  let(:schema) {
    node_type = GraphQL::InterfaceType.define do
      name "Node"

      field :id, !types.ID
    end

    choice_type = GraphQL::EnumType.define do
      name "Choice"

      value "FOO", value: :foo
      value "BAR", value: :bar
      value "BAZ", deprecation_reason: <<-REASON
Use "BAR" instead.

It's the replacement for this value.
REASON
      value "WOZ", deprecation_reason: GraphQL::Directive::DEFAULT_DEPRECATION_REASON
    end

    sub_input_type = GraphQL::InputObjectType.define do
      name "Sub"
      description "Test"
      input_field :string, types.String, "Something"
      input_field :int, types.Int, "Something"
    end

    variant_input_type = GraphQL::InputObjectType.define do
      name "Varied"
      input_field :id, types.ID
      input_field :int, types.Int
      input_field :float, types.Float
      input_field :bool, types.Boolean
      input_field :enum, choice_type, default_value: :foo
      input_field :sub, types[sub_input_type]
    end

    comment_type = GraphQL::ObjectType.define do
      name "Comment"
      description "A blog comment"
      interfaces [node_type]

      field :id, !types.ID
    end

    post_type = GraphQL::ObjectType.define do
      name "Post"
      description "A blog post"

      field :id, !types.ID
      field :title, !types.String
      field :body, !types.String
      field :comments, types[!comment_type]
      field :comments_count, !types.Int, deprecation_reason: 'Use "comments".'
    end

    audio_type = GraphQL::ObjectType.define do
      name "Audio"

      field :id, !types.ID
      field :name, !types.String
      field :duration, !types.Int
    end

    image_type = GraphQL::ObjectType.define do
      name "Image"

      field :id, !types.ID
      field :name, !types.String
      field :width, !types.Int
      field :height, !types.Int
    end

    media_union_type = GraphQL::UnionType.define do
      name "Media"
      description "Media objects"

      possible_types [image_type, audio_type]
    end

    query_root = GraphQL::ObjectType.define do
      name "Query"
      description "The query root of this schema"

      field :post do
        type post_type
        argument :id, !types.ID, "Post ID"
        argument :varied, variant_input_type, default_value: {id: "123", int: 234, float: 2.3, enum: :foo, sub: [{string: "str"}]}
        argument :variedWithNulls, variant_input_type, default_value: {id: nil, int: nil, float: nil, enum: nil, sub: nil}
        resolve -> (obj, args, ctx) { Post.find(args["id"]) }
      end
    end

    create_post_mutation = GraphQL::Relay::Mutation.define do
      name "CreatePost"
      description "Create a blog post"

      input_field :title, !types.String
      input_field :body, !types.String

      return_field :post, post_type

      resolve -> (_, _, _) { }
    end

    mutation_root = GraphQL::ObjectType.define do
      name "Mutation"

      field :createPost, field: create_post_mutation.field
    end

    subscription_root = GraphQL::ObjectType.define do
      name "Subscription"

      field :post do
        type post_type
        argument :id, !types.ID
        resolve -> (_, _, _) { }
      end
    end

    GraphQL::Schema.define(
      query: query_root,
      mutation: mutation_root,
      subscription: subscription_root,
      resolve_type: -> (a, b, c) { :pass },
      orphan_types: [media_union_type],
    )
  }

  describe ".print_introspection_schema" do
    it "returns the schema as a string for the introspection types" do
      # From https://github.com/graphql/graphql-js/blob/6a0e00fe46951767287f2cc62e1a10b167b2eaa6/src/utilities/__tests__/schemaPrinter-test.js#L599
      expected = <<SCHEMA
schema {
  query: Root
}

# Marks an element of a GraphQL schema as no longer supported.
directive @deprecated(
  # Explains why this element was deprecated, usually also including a suggestion
  # for how to access supported similar data. Formatted in
  # [Markdown](https://daringfireball.net/projects/markdown/).
  reason: String = "No longer supported"
) on FIELD_DEFINITION | ENUM_VALUE

# Directs the executor to include this field or fragment only when the `if` argument is true.
directive @include(
  # Included when true.
  if: Boolean!
) on FIELD | FRAGMENT_SPREAD | INLINE_FRAGMENT

# Directs the executor to skip this field or fragment when the `if` argument is true.
directive @skip(
  # Skipped when true.
  if: Boolean!
) on FIELD | FRAGMENT_SPREAD | INLINE_FRAGMENT

# A Directive provides a way to describe alternate runtime execution and type validation behavior in a GraphQL document.
#
# In some cases, you need to provide options to alter GraphQL's execution behavior
# in ways field arguments will not suffice, such as conditionally including or
# skipping a field. Directives provide this by describing additional information
# to the executor.
type __Directive {
  args: [__InputValue!]!
  description: String
  locations: [__DirectiveLocation!]!
  name: String!
  onField: Boolean! @deprecated(reason: "Use `locations`.")
  onFragment: Boolean! @deprecated(reason: "Use `locations`.")
  onOperation: Boolean! @deprecated(reason: "Use `locations`.")
}

# A Directive can be adjacent to many parts of the GraphQL language, a
# __DirectiveLocation describes one such possible adjacencies.
enum __DirectiveLocation {
  # Location adjacent to an argument definition.
  ARGUMENT_DEFINITION

  # Location adjacent to an enum definition.
  ENUM

  # Location adjacent to an enum value definition.
  ENUM_VALUE

  # Location adjacent to a field.
  FIELD

  # Location adjacent to a field definition.
  FIELD_DEFINITION

  # Location adjacent to a fragment definition.
  FRAGMENT_DEFINITION

  # Location adjacent to a fragment spread.
  FRAGMENT_SPREAD

  # Location adjacent to an inline fragment.
  INLINE_FRAGMENT

  # Location adjacent to an input object field definition.
  INPUT_FIELD_DEFINITION

  # Location adjacent to an input object type definition.
  INPUT_OBJECT

  # Location adjacent to an interface definition.
  INTERFACE

  # Location adjacent to a mutation operation.
  MUTATION

  # Location adjacent to an object type definition.
  OBJECT

  # Location adjacent to a query operation.
  QUERY

  # Location adjacent to a scalar definition.
  SCALAR

  # Location adjacent to a schema definition.
  SCHEMA

  # Location adjacent to a subscription operation.
  SUBSCRIPTION

  # Location adjacent to a union definition.
  UNION
}

# One possible value for a given Enum. Enum values are unique values, not a
# placeholder for a string or numeric value. However an Enum value is returned in
# a JSON response as a string.
type __EnumValue {
  deprecationReason: String
  description: String
  isDeprecated: Boolean!
  name: String!
}

# Object and Interface types are described by a list of Fields, each of which has
# a name, potentially a list of arguments, and a return type.
type __Field {
  args: [__InputValue!]!
  deprecationReason: String
  description: String
  isDeprecated: Boolean!
  name: String!
  type: __Type!
}

# Arguments provided to Fields or Directives and the input fields of an
# InputObject are represented as Input Values which describe their type and
# optionally a default value.
type __InputValue {
  # A GraphQL-formatted string representing the default value for this input value.
  defaultValue: String
  description: String
  name: String!
  type: __Type!
}

# A GraphQL Schema defines the capabilities of a GraphQL server. It exposes all
# available types and directives on the server, as well as the entry points for
# query, mutation, and subscription operations.
type __Schema {
  # A list of all directives supported by this server.
  directives: [__Directive!]!

  # If this server supports mutation, the type that mutation operations will be rooted at.
  mutationType: __Type

  # The type that query operations will be rooted at.
  queryType: __Type!

  # If this server support subscription, the type that subscription operations will be rooted at.
  subscriptionType: __Type

  # A list of all types supported by this server.
  types: [__Type!]!
}

# The fundamental unit of any GraphQL Schema is the type. There are many kinds of
# types in GraphQL as represented by the `__TypeKind` enum.
#
# Depending on the kind of a type, certain fields describe information about that
# type. Scalar types provide no information beyond a name and description, while
# Enum types provide their values. Object and Interface types provide the fields
# they describe. Abstract types, Union and Interface, provide the Object types
# possible at runtime. List and NonNull types compose other types.
type __Type {
  description: String
  enumValues(includeDeprecated: Boolean = false): [__EnumValue!]
  fields(includeDeprecated: Boolean = false): [__Field!]
  inputFields: [__InputValue!]
  interfaces: [__Type!]
  kind: __TypeKind!
  name: String
  ofType: __Type
  possibleTypes: [__Type!]
}

# An enum describing what kind of type a given `__Type` is.
enum __TypeKind {
  # Indicates this type is an enum. `enumValues` is a valid field.
  ENUM

  # Indicates this type is an input object. `inputFields` is a valid field.
  INPUT_OBJECT

  # Indicates this type is an interface. `fields` and `possibleTypes` are valid fields.
  INTERFACE

  # Indicates this type is a list. `ofType` is a valid field.
  LIST

  # Indicates this type is a non-null. `ofType` is a valid field.
  NON_NULL

  # Indicates this type is an object. `fields` and `interfaces` are valid fields.
  OBJECT

  # Indicates this type is a scalar.
  SCALAR

  # Indicates this type is a union. `possibleTypes` is a valid field.
  UNION
}
SCHEMA
      assert_equal expected.chomp, GraphQL::Schema::Printer.print_introspection_schema
    end
  end

  describe ".print_schema" do
    it "includes schema definition when query root name doesn't match convention" do
      custom_query = schema.query.redefine(name: "MyQueryRoot")
      custom_schema = schema.redefine(query: custom_query)

      expected = <<SCHEMA
schema {
  query: MyQueryRoot
  mutation: Mutation
  subscription: Subscription
}
SCHEMA
      assert_match expected, GraphQL::Schema::Printer.print_schema(custom_schema)
    end

    it "includes schema definition when mutation root name doesn't match convention" do
      custom_mutation = schema.mutation.redefine(name: "MyMutationRoot")
      custom_schema = schema.redefine(mutation: custom_mutation)

      expected = <<SCHEMA
schema {
  query: Query
  mutation: MyMutationRoot
  subscription: Subscription
}
SCHEMA

      assert_match expected, GraphQL::Schema::Printer.print_schema(custom_schema)
    end

    it "includes schema definition when subscription root name doesn't match convention" do
      custom_subscription = schema.subscription.redefine(name: "MySubscriptionRoot")
      custom_schema = schema.redefine(subscription: custom_subscription)

      expected = <<SCHEMA
schema {
  query: Query
  mutation: Mutation
  subscription: MySubscriptionRoot
}
SCHEMA

      assert_match expected, GraphQL::Schema::Printer.print_schema(custom_schema)
    end

    it "returns the schema as a string for the defined types" do
      expected = <<SCHEMA
type Audio {
  duration: Int!
  id: ID!
  name: String!
}

enum Choice {
  BAR
  BAZ @deprecated(reason: "Use \\\"BAR\\\" instead.\\n\\nIt's the replacement for this value.\\n")
  FOO
  WOZ @deprecated
}

# A blog comment
type Comment implements Node {
  id: ID!
}

# Autogenerated input type of CreatePost
input CreatePostInput {
  body: String!

  # A unique identifier for the client performing the mutation.
  clientMutationId: String
  title: String!
}

# Autogenerated return type of CreatePost
type CreatePostPayload {
  # A unique identifier for the client performing the mutation.
  clientMutationId: String
  post: Post
}

type Image {
  height: Int!
  id: ID!
  name: String!
  width: Int!
}

# Media objects
union Media = Audio | Image

type Mutation {
  # Create a blog post
  createPost(input: CreatePostInput!): CreatePostPayload
}

interface Node {
  id: ID!
}

# A blog post
type Post {
  body: String!
  comments: [Comment!]
  comments_count: Int! @deprecated(reason: "Use \\\"comments\\\".")
  id: ID!
  title: String!
}

# The query root of this schema
type Query {
  post(
    # Post ID
    id: ID!
    varied: Varied = {id: "123", int: 234, float: 2.3, enum: FOO, sub: [{string: "str"}]}
    variedWithNulls: Varied = {id: null, int: null, float: null, enum: null, sub: null}
  ): Post
}

# Test
input Sub {
  # Something
  int: Int

  # Something
  string: String
}

type Subscription {
  post(id: ID!): Post
}

input Varied {
  bool: Boolean
  enum: Choice = FOO
  float: Float
  id: ID
  int: Int
  sub: [Sub]
}
SCHEMA

      assert_equal expected.chomp, GraphQL::Schema::Printer.print_schema(schema)
    end

    it "prints a schema without directives" do
      query_type = Class.new(GraphQL::Schema::Object) do
        graphql_name "Query"

        field :foobar, Integer, null: false

        def foobar
          152
        end
      end

      schema = Class.new(GraphQL::Schema) do
        query query_type
      end

      expected = "type Query {\n  foobar: Int!\n}"
      assert_equal expected, GraphQL::Schema::Printer.new(schema).print_schema
    end
  end

  it "applies an `only` filter" do
    expected = <<SCHEMA
enum Choice {
  BAR
  FOO
}

type Subscription {
}

input Varied {
  bool: Boolean
  enum: Choice = FOO
  float: Float
  int: Int
}
SCHEMA

    only_filter = -> (member, ctx) {
      case member
      when GraphQL::ScalarType
        true
      when GraphQL::BaseType
        ctx[:names].include?(member.name)
      when GraphQL::Argument
        member.name != "id"
      else
        if member.respond_to?(:deprecation_reason)
          member.deprecation_reason.nil?
        end
      end
    }

    context = {names: ["Varied", "Choice", "Subscription"]}
    assert_equal expected.chomp, schema.to_definition(context: context, only: only_filter)
  end

  it "applies an `except` filter" do
    expected = <<SCHEMA
type Audio {
  duration: Int!
  id: ID!
  name: String!
}

enum Choice {
  BAR
  FOO
}

# A blog comment
type Comment implements Node {
  id: ID!
}

# Autogenerated input type of CreatePost
input CreatePostInput {
  body: String!

  # A unique identifier for the client performing the mutation.
  clientMutationId: String
  title: String!
}

# Autogenerated return type of CreatePost
type CreatePostPayload {
  # A unique identifier for the client performing the mutation.
  clientMutationId: String
  post: Post
}

# Media objects
union Media = Audio

type Mutation {
  # Create a blog post
  createPost(input: CreatePostInput!): CreatePostPayload
}

interface Node {
  id: ID!
}

# A blog post
type Post {
  body: String!
  comments: [Comment!]
  id: ID!
  title: String!
}

# The query root of this schema
type Query {
  post(
    # Post ID
    id: ID!
  ): Post
}

type Subscription {
  post(id: ID!): Post
}
SCHEMA

    except_filter = -> (member, ctx) {
      ctx[:names].include?(member.name) || (member.respond_to?(:deprecation_reason) && member.deprecation_reason)
    }

    context = {names: ["Varied", "Image", "Sub"]}
    assert_equal expected.chomp, schema.to_definition(context: context, except: except_filter)
  end

  describe "#print_type" do
    it "returns the type schema as a string" do
      expected = <<SCHEMA
# A blog post
type Post {
  body: String!
  comments: [Comment!]
  comments_count: Int! @deprecated(reason: "Use \\\"comments\\\".")
  id: ID!
  title: String!
}
SCHEMA
      assert_equal expected.chomp, GraphQL::Schema::Printer.new(schema).print_type(schema.types["Post"])
    end

    it "can print arguments that use non-standard Ruby objects as default values" do
      backing_object = Struct.new(:value)

      scalar_type = GraphQL::ScalarType.define do
        name "SomeType"
        coerce_input -> (value, ctx) { backing_object.new(value) }
        coerce_result -> (obj, ctx) { obj.value }
      end

      query_root = GraphQL::ObjectType.define do
        name "Query"
        description "The query root of this schema"

        field :example do
          type scalar_type
          argument :input, scalar_type, default_value: backing_object.new("Howdy")
          resolve -> (obj, args, ctx) { args[:input] }
        end
      end

      schema = GraphQL::Schema.define do
        query query_root
      end

      expected = <<SCHEMA
# The query root of this schema
type Query {
  example(input: SomeType = "Howdy"): SomeType
}
SCHEMA

      assert_equal expected.chomp, GraphQL::Schema::Printer.new(schema).print_type(query_root)
    end
  end

  describe "#print_directive" do
    it "prints the deprecation reason in a single line escaped string including line breaks" do
      expected = <<SCHEMA
enum Choice {
  BAR
  BAZ @deprecated(reason: "Use \\\"BAR\\\" instead.\\n\\nIt's the replacement for this value.\\n")
  FOO
  WOZ @deprecated
}

type Subscription {
}

input Varied {
  bool: Boolean
  enum: Choice = FOO
  float: Float
  int: Int
}
SCHEMA

      only_filter = -> (member, ctx) {
        case member
        when GraphQL::ScalarType
          true
        when GraphQL::BaseType
          ctx[:names].include?(member.name)
        when GraphQL::Argument
          member.name != "id"
        else
          true
        end
      }

      context = {names: ["Varied", "Choice", "Subscription"]}

      assert_equal expected.chomp, GraphQL::Schema::Printer.new(schema, context: context, only: only_filter).print_schema
    end
  end
end
