# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::ReduceTypes do
  def reduce_types(types, camelize: false)
    GraphQL::Schema::ReduceTypes.reduce(types, camelize: camelize)
  end

  it "finds types from a single type and its fields" do
    expected = {
      "Cheese" => Dummy::CheeseType,
      "Int" => GraphQL::INT_TYPE,
      "String" => GraphQL::STRING_TYPE,
      "DairyAnimal" => Dummy::DairyAnimalEnum,
      "Float" => GraphQL::FLOAT_TYPE,
      "Edible" => Dummy::EdibleInterface,
      "AnimalProduct" => Dummy::AnimalProductInterface,
      "LocalProduct" => Dummy::LocalProductInterface,
    }
    result = reduce_types([Dummy::CheeseType])
    assert_equal(expected.keys, result.keys)
    assert_equal(expected, result.to_h)
  end

  it "finds type from arguments" do
    result = reduce_types([Dummy::DairyAppQueryType])
    assert_equal(Dummy::DairyProductInputType, result["DairyProductInput"])
  end

  it "finds types from nested InputObjectTypes" do
    type_child = GraphQL::InputObjectType.define do
      name "InputTypeChild"
      input_field :someField, GraphQL::STRING_TYPE
    end

    type_parent = GraphQL::InputObjectType.define do
      name "InputTypeParent"
      input_field :child, type_child
    end

    result = reduce_types([type_parent])
    expected = {
      "InputTypeParent" => type_parent,
      "InputTypeChild" => type_child,
      "String" => GraphQL::STRING_TYPE
    }
    assert_equal(expected, result.to_h)
  end

  describe "when a type is invalid" do
    let(:invalid_type) {
      GraphQL::ObjectType.define do
        name "InvalidType"
        field :someField
      end
    }

    let(:another_invalid_type) {
      GraphQL::ObjectType.define do
        name "AnotherInvalidType"
        field :someField, String
      end
    }

    it "raises an InvalidTypeError when passed nil" do
      assert_raises(GraphQL::Schema::InvalidTypeError) {  reduce_types([invalid_type]) }
    end

    it "raises an InvalidTypeError when passed an object that isnt a GraphQL::BaseType" do
      assert_raises(GraphQL::Schema::InvalidTypeError) {  reduce_types([another_invalid_type]) }
    end
  end

  describe "when a schema has multiple types with the same name" do
    let(:type_1) {
      GraphQL::ObjectType.define do
        name "MyType"
      end
    }
    let(:type_2) {
      GraphQL::ObjectType.define do
        name "MyType"
      end
    }
    it "raises an error" do
      assert_raises(RuntimeError) {
        reduce_types([type_1, type_2])
      }
    end
  end

  describe "when camelize is true" do
    let(:type) {
      GraphQL::ObjectType.define do
        name "MyType"
        field :my_field, types.String
        field :withArguments, types.String do
          argument :my_argument, types.String
        end
      end
    }

    let(:input_type) {
      GraphQL::InputObjectType.define do
        name "MyInputType"
        argument :my_input_argument, types.String
      end
    }

    let(:types) {
      reduce_types([type, input_type], camelize: true)
    }

    it "camelizes field names" do
      expected_field = types["MyType"].fields["myField"]

      assert_nil types["MyType"].fields["my_field"]
      assert expected_field
      assert_equal :my_field, expected_field.property
    end


    it "camelizes arguments" do
      field_with_arguments = types["MyType"].fields["withArguments"]

      expected_argument = field_with_arguments.arguments["myArgument"]

      assert_nil field_with_arguments.arguments["my_argument"]
      assert expected_argument
      assert_equal "my_argument", expected_argument.expose_as
    end

    it "camelizes input object type arguments" do
      expected_argument = types["MyInputType"].arguments["myInputArgument"]

      assert_nil types["MyInputType"].arguments["my_input_argument"]
      assert expected_argument
      assert_equal "my_input_argument", expected_argument.expose_as
    end
  end

  describe "when getting a type which doesnt exist" do
    it "raises an error" do
      type_map = reduce_types([])
      assert_raises(RuntimeError) { type_map["SomeType"] }
    end
  end

  describe "when a field is only accessible through an interface" do
    it "is found through Schema.define(types:)" do
      assert_equal Dummy::HoneyType, Dummy::Schema.types["Honey"]
    end
  end
end
