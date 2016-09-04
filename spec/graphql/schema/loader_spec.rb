require "spec_helper"

describe GraphQL::Schema::Loader do
  let(:schema) {
    node_type = GraphQL::InterfaceType.define do
      name "Node"

      field :id, !types.ID
    end

    choice_type = GraphQL::EnumType.define do
      name "Choice"

      value "FOO"
      value "BAR"
    end

    sub_input_type = GraphQL::InputObjectType.define do
      name "Sub"
      input_field :string, types.String
    end

    big_int_type = GraphQL::ScalarType.define do
      name "BigInt"
      coerce_input -> (value) { value =~ /\d+/ ? Integer(value) : nil }
      coerce_result -> (value) { value.to_s }
    end

    variant_input_type = GraphQL::InputObjectType.define do
      name "Varied"
      input_field :id, types.ID
      input_field :int, types.Int
      input_field :bigint, big_int_type
      input_field :float, types.Float
      input_field :bool, types.Boolean
      input_field :enum, choice_type
      input_field :sub, types[sub_input_type]
    end

    comment_type = GraphQL::ObjectType.define do
      name "Comment"
      description "A blog comment"
      interfaces [node_type]

      field :body, !types.String
    end

    post_type = GraphQL::ObjectType.define do
      name "Post"
      description "A blog post"

      field :id, !types.ID
      field :title, !types.String
      field :body, !types.String
      field :comments, types[!comment_type]
    end

    content_type = GraphQL::UnionType.define do
      name "Content"
      description "A post or comment"
      possible_types [post_type, comment_type]
    end

    query_root = GraphQL::ObjectType.define do
      name "Query"
      description "The query root of this schema"

      field :post do
        type post_type
        argument :id, !types.ID
        argument :varied, variant_input_type, default_value: { id: "123", int: 234, float: 2.3, enum: "FOO", sub: [{ string: "str" }] }
      end

      field :content do
        type content_type
      end
    end

    GraphQL::Schema.define(query: query_root)
  }

  let(:schema_json) {
    schema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)
  }

  describe "load" do
    def assert_deep_equal(expected_type, actual_type)
      assert_equal expected_type.class, actual_type.class

      case actual_type
      when Array
        actual_type.each_with_index do |obj, index|
          assert_deep_equal expected_type[index], obj
        end

      when GraphQL::Schema
        assert_equal expected_type.query.name, actual_type.query.name
        assert_equal expected_type.directives.keys.sort, actual_type.directives.keys.sort
        assert_equal expected_type.types.keys.sort, actual_type.types.keys.sort
        assert_deep_equal expected_type.types.values.sort_by(&:name), actual_type.types.values.sort_by(&:name)

      when GraphQL::ObjectType, GraphQL::InterfaceType
        assert_equal expected_type.name, actual_type.name
        assert_equal expected_type.description, actual_type.description
        assert_deep_equal expected_type.all_fields.sort_by(&:name), actual_type.all_fields.sort_by(&:name)

      when GraphQL::Field
        assert_equal expected_type.name, actual_type.name
        assert_equal expected_type.description, actual_type.description
        assert_equal expected_type.arguments.keys, actual_type.arguments.keys
        assert_deep_equal expected_type.arguments.values, actual_type.arguments.values

      when GraphQL::ScalarType
        assert_equal expected_type.name, actual_type.name

      when GraphQL::EnumType
        assert_equal expected_type.name, actual_type.name
        assert_equal expected_type.description, actual_type.description
        assert_equal expected_type.values.keys, actual_type.values.keys
        assert_deep_equal expected_type.values.values, actual_type.values.values

      when GraphQL::EnumType::EnumValue
        assert_equal expected_type.name, actual_type.name
        assert_equal expected_type.description, actual_type.description

      when GraphQL::Argument
        assert_equal expected_type.name, actual_type.name
        assert_equal expected_type.description, actual_type.description
        assert_deep_equal expected_type.type, actual_type.type

      when GraphQL::InputObjectType
        assert_equal expected_type.arguments.keys, actual_type.arguments.keys
        assert_deep_equal expected_type.arguments.values, actual_type.arguments.values

      when GraphQL::NonNullType, GraphQL::ListType
        assert_deep_equal expected_type.of_type, actual_type.of_type

      else
        assert_equal expected_type, actual_type
      end
    end

    it "returns the schema" do
      assert_deep_equal(schema, GraphQL::Schema::Loader.load(schema_json))
    end
  end
end
