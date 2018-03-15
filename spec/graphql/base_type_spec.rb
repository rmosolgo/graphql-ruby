# frozen_string_literal: true
require "spec_helper"

describe GraphQL::BaseType do
  it "becomes non-null with !" do
    type = GraphQL::EnumType.new
    non_null_type = !type
    assert_equal(GraphQL::TypeKinds::NON_NULL, non_null_type.kind)
    assert_equal(type, non_null_type.of_type)
    assert_equal(GraphQL::TypeKinds::NON_NULL, (!GraphQL::STRING_TYPE).kind)
  end

  it "can be compared" do
    obj_type = Dummy::MilkType
    assert_equal(!GraphQL::INT_TYPE, !GraphQL::INT_TYPE)
    refute_equal(!GraphQL::FLOAT_TYPE, GraphQL::FLOAT_TYPE)
    assert_equal(
      GraphQL::ListType.new(of_type: obj_type),
      GraphQL::ListType.new(of_type: obj_type)
    )
    refute_equal(
      GraphQL::ListType.new(of_type: obj_type),
      GraphQL::ListType.new(of_type: !obj_type)
    )
  end

  it "Accepts arbitrary metadata" do
    assert_equal ["Cheese"], Dummy::CheeseType.metadata[:class_names]
  end

  describe "#name" do
    describe "when containing spaces" do
      BaseNameSpaceTest = GraphQL::BaseType.define do
        name "Some Invalid Name"
      end

      it "is invalid" do
        assert_raises(GraphQL::InvalidNameError) { BaseNameSpaceTest.name }
      end
    end

    describe "when containing colons" do
      BaseNameColonsTest = GraphQL::BaseType.define do
        name "Some::Invalid::Name"
      end

      it 'is invalid' do
        assert_raises(GraphQL::InvalidNameError) { BaseNameColonsTest.name }
      end
    end
  end

  describe "name" do
    it "fails with a helpful message" do
      error = assert_raises RuntimeError do
        class BaseType < GraphQL::Schema::Object
          name "KerkShine"
        end
      end

      assert_equal error.message, "The new name override method is `graphql_name`, not `name`. Usage: graphql_name \"KerkShine\""
    end
  end

  describe "forwards-compat with new api" do
    let(:type_defn) { Dummy::CheeseType }
    it "responds to new methods" do
      assert_equal "Cheese", type_defn.graphql_name
      assert_equal type_defn, type_defn.graphql_definition
    end
  end

  describe "#dup" do
    let(:obj_type) {
      GraphQL::ObjectType.define do
        name "SomeObject"
        field :id, types.Int
      end
    }

    it "resets connection types" do
      # Make sure the defaults have been calculated
      obj_edge = obj_type.edge_type
      obj_conn = obj_type.connection_type
      obj_2 = obj_type.dup
      obj_2.name = "Cheese2"
      refute_equal obj_edge, obj_2.edge_type
      refute_equal obj_conn, obj_2.connection_type
    end
  end

  describe "#to_definition" do
    post_type = GraphQL::ObjectType.define do
      name "Post"
      description "A blog post"

      field :id, !types.ID
      field :title, !types.String
      field :body, !types.String
    end

    query_root = GraphQL::ObjectType.define do
      name "Query"
      description "The query root of this schema"

      field :post do
        type post_type
        resolve ->(obj, args, ctx) { Post.find(args["id"]) }
      end
    end

    schema = GraphQL::Schema.define(query: query_root)

    expected = <<TYPE
# A blog post
type Post {
  body: String!
  id: ID!
  title: String!
}
TYPE

    it "prints the type definition" do
      assert_equal expected.chomp, post_type.to_definition(schema)
    end
  end

  describe 'non_null?' do
    let(:type) do
      GraphQL::EnumType.define do
        name "Hello"
        value 'WORLD'
      end
    end

    it "returns false for nullable types" do
      assert_equal(type.non_null?, false)
    end

    it "returns true for non-nulls" do
      assert_equal(type.to_non_null_type.non_null?, true)
    end

    it "returns false for a nullable list of non-nulls" do
      assert_equal(type.to_non_null_type.to_list_type.non_null?, false)
    end
  end

  describe 'list?' do
    let(:type) do
      GraphQL::EnumType.define do
        name "Hello"
        value 'WORLD'
      end
    end

    it "returns false for non-list types" do
      assert_equal(type.list?, false)
    end

    it "returns true for lists" do
      assert_equal(type.to_list_type.list?, true)
    end

    it "returns true for a non-nullable list" do
      assert_equal(type.to_list_type.to_non_null_type.list?, true)
    end
  end
end
