# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Loader do
  let(:schema) {
    node_type = GraphQL::InterfaceType.define do
      name "Node"

      field :id, !types.ID
    end

    choice_type = GraphQL::EnumType.define do
      name "Choice"

      value "FOO", value: :foo
      value "BAR"
    end

    sub_input_type = GraphQL::InputObjectType.define do
      name "Sub"
      input_field :string, types.String
    end

    big_int_type = GraphQL::ScalarType.define do
      name "BigInt"
      coerce_input ->(value, _ctx) { value =~ /\d+/ ? Integer(value) : nil }
      coerce_result ->(value, _ctx) { value.to_s }
    end

    variant_input_type = GraphQL::InputObjectType.define do
      name "Varied"
      input_field :id, types.ID
      input_field :int, types.Int
      input_field :bigint, big_int_type, default_value: 2**54
      input_field :float, types.Float
      input_field :bool, types.Boolean
      input_field :enum, choice_type
      input_field :sub, types[sub_input_type]
    end

    variant_input_type_with_nulls = GraphQL::InputObjectType.define do
      name "VariedWithNulls"
      input_field :id, types.ID, default_value: nil
      input_field :int, types.Int, default_value: nil
      input_field :bigint, big_int_type, default_value: nil
      input_field :float, types.Float, default_value: nil
      input_field :bool, types.Boolean, default_value: nil
      input_field :enum, choice_type, default_value: nil
      input_field :sub, types[sub_input_type], default_value: nil
    end

    comment_type = GraphQL::ObjectType.define do
      name "Comment"
      description "A blog comment"
      interfaces [node_type]

      field :body, !types.String

      field :fieldWithArg, types.Int do
        argument :bigint, big_int_type, default_value: 2**54
      end
    end

    media_type = GraphQL::InterfaceType.define do
      name "Media"
      description "!!!"
      field :type, !types.String
    end

    video_type = GraphQL::ObjectType.define do
      name "Video"
      interfaces [media_type]
    end

    audio_type = GraphQL::ObjectType.define do
      name "Audio"
      interfaces [media_type]
    end

    post_type = GraphQL::ObjectType.define do
      name "Post"
      description "A blog post"

      field :id, !types.ID
      field :title, !types.String
      field :body, !types.String
      field :comments, types[!comment_type]
      field :attachment, media_type
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
        argument :varied, variant_input_type, default_value: { id: "123", int: 234, float: 2.3, enum: :foo, sub: [{ string: "str" }] }
        argument :variedWithNull, variant_input_type_with_nulls, default_value: { id: nil, int: nil, float: nil, enum: nil, sub: nil, bigint: nil, bool: nil }
        argument :enum, choice_type, default_value: :foo
        argument :array, types[!types.String], default_value: ["foo", "bar"]
      end

      field :content do
        type content_type
      end
    end

    ping_mutation = GraphQL::Relay::Mutation.define do
      name "Ping"
    end

    mutation_root = GraphQL::ObjectType.define do
      name "Mutation"
      field :ping, field: ping_mutation.field
    end

    GraphQL::Schema.define(
      query: query_root,
      mutation: mutation_root,
      orphan_types: [audio_type, video_type],
      resolve_type: ->(a,b,c) { :pass },
    )
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

    let(:loaded_schema) { GraphQL::Schema::Loader.load(schema_json) }

    it "returns the schema" do
      assert_deep_equal(schema, loaded_schema)
    end

    it "can export the loaded schema" do
      assert loaded_schema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)
    end

    it "has no-op coerce functions" do
      custom_scalar = loaded_schema.types["BigInt"]
      assert_equal true, custom_scalar.valid_isolated_input?("anything")
      assert_equal true, custom_scalar.valid_isolated_input?(12345)
    end

    it "sets correct default values on custom scalar arguments" do
      type = loaded_schema.types["Comment"]
      field = type.fields['fieldWithArg']
      arg = field.arguments['bigint']

      assert_equal((2**54).to_s, arg.default_value)
    end

    it "sets correct default values on custom scalar input fields" do
      type = loaded_schema.types["Varied"]
      field = type.input_fields['bigint']

      assert_equal((2**54).to_s, field.default_value)
    end

    it "sets correct default values for complex field arguments" do
      type = loaded_schema.types['Query']
      field = type.fields['post']

      varied = field.arguments['varied']
      assert_equal varied.default_value, { 'id' => "123", 'int' => 234, 'float' => 2.3, 'enum' => "FOO", 'sub' => [{ 'string' => "str" }] }
      assert !varied.default_value.key?('bool'), 'Omits default value for unspecified arguments'

      array = field.arguments['array']
      assert_equal array.default_value, ["foo", "bar"]
    end

    it "does not set default value when there are none on input fields" do
      type = loaded_schema.types['Varied']

      assert !type.arguments['id'].default_value?
      assert !type.arguments['int'].default_value?
      assert type.arguments['bigint'].default_value?
      assert !type.arguments['float'].default_value?
      assert !type.arguments['bool'].default_value?
      assert !type.arguments['enum'].default_value?
      assert !type.arguments['sub'].default_value?
    end

    it "sets correct default values `null` on input fields" do
      type = loaded_schema.types['VariedWithNulls']

      assert type.arguments['id'].default_value?
      assert type.arguments['id'].default_value.nil?

      assert type.arguments['int'].default_value?
      assert type.arguments['int'].default_value.nil?

      assert type.arguments['bigint'].default_value?
      assert type.arguments['bigint'].default_value.nil?

      assert type.arguments['float'].default_value?
      assert type.arguments['float'].default_value.nil?

      assert type.arguments['bool'].default_value?
      assert type.arguments['bool'].default_value.nil?

      assert type.arguments['enum'].default_value?
      assert type.arguments['enum'].default_value.nil?

      assert type.arguments['sub'].default_value?
      assert type.arguments['sub'].default_value.nil?
    end

    it "sets correct default values `null` on complex field arguments" do
      type = loaded_schema.types['Query']
      field = type.fields['post']
      arg = field.arguments['variedWithNull']

      assert_equal arg.default_value, { 'id' => nil, 'int' => nil, 'float' => nil, 'enum' => nil, 'sub' => nil, 'bool' => nil, 'bigint' => nil }
    end
  end
end
