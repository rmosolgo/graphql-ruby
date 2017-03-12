# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::DefinitionDependencies do
  describe "infinite loop bug" do
    let(:resolvers) {
      user =
      icon = OpenStruct.new(icon: "x", category: "y")
      sub_comment_1 = OpenStruct.new(id: "3", icon: icon, user: OpenStruct.new(first_name: "A", last_name: "B", id: "21"))
      sub_comment_2 = OpenStruct.new(id: "4", icon: icon, user: OpenStruct.new(first_name: "C", last_name: "D", id: "22"))
      comment = OpenStruct.new(id: "2", comments: [sub_comment_1, sub_comment_2])
      resolvers = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = ->(o, a, c) { o.public_send(k2) } } }
      resolvers["Query"]["node"] = ->(o, a, c) { comment }
      resolvers
    }

    let(:schema_defn) { <<-GRAPHQL
    type Query {
      node(id: ID!): Commentable
    }

    interface Commentable {
      id: ID!
      comments: [Comment]
    }

    type User {
      first_name: String
      last_name: String
      id: ID!
    }

    type Icon {
      icon: String
      category: String
    }

    type Comment implements Commentable {
      id: ID!
      comment: String
      comments: [Comment]
      created_at: String
      can_delete: Boolean
      deleted_at: String
      user: User
      icon: Icon
    }
    GRAPHQL
    }
    let(:schema) {
      s = GraphQL::Schema.from_definition(schema_defn, default_resolve: resolvers)
      comment_type = s.types["Comment"]
      s.resolve_type = ->(obj, ctx) { s.types["Comment"] }
      s
    }
    let(:query_string) { <<-GRAPHQL
      query CommentableUI_CommentableRelayQL($id_0:ID!) {
        node(id:$id_0) {
          id,
          __typename,
          ...F4
        }
      }
      fragment F0 on Comment {
        id
      }
      fragment F1 on Comment {
        id,
        ...F0
      }
      fragment F2 on Comment {
        id,
        comment,
        icon {
          icon,
          category
        },
        user {
          first_name,
          last_name,
          id
        },
        can_delete,
        created_at,
        ...F1
      }
      fragment F3 on Commentable {
        id,
        __typename
      }
      fragment F4 on Commentable {
        id,
        comments {
          deleted_at,
          id,
          ...F2
        },
        __typename,
        ...F3
      }
    GRAPHQL
    }

    it "validates ok" do
      error_messages = schema.validate(query_string).map(&:message)
      assert_equal [], error_messages
    end

    it "executes ok" do
      res = schema.execute(query_string, variables: {"id_0" => "5"})
      pp res
      comment = res["data"]["node"]
      assert_equal "2", comment["id"]
      assert_equal "A", comment["comments"][0]["user"]["first_name"]
      assert_equal "C", comment["comments"][1]["user"]["first_name"]
      assert_equal "x", comment["comments"][0]["icon"]["icon"]
    end
  end
end
