# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Traversal do
  def reduce_types(types)
    schema = GraphQL::Schema.define(orphan_types: types, resolve_type: :dummy)
    traversal = GraphQL::Schema::Traversal.new(schema, introspection: false)
    traversal.type_map
  end

  it "finds types from directives" do
    expected = {
      "Boolean" => GraphQL::BOOLEAN_TYPE, # `skip` argument
      "String" => GraphQL::STRING_TYPE # `deprecated` argument
    }
    result = reduce_types([])
    assert_equal(expected.keys.sort, result.keys.sort)
    assert_equal(expected, result.to_h)
  end

  it "finds types from a single type and its fields" do
    expected = {
      "Cheese" => Dummy::CheeseType,
      "Float" => GraphQL::FLOAT_TYPE,
      "String" => GraphQL::STRING_TYPE,
      "Edible" => Dummy::EdibleInterface,
      "EdibleAsMilk" => Dummy::EdibleAsMilkInterface,
      "DairyAnimal" => Dummy::DairyAnimalEnum,
      "Int" => GraphQL::INT_TYPE,
      "AnimalProduct" => Dummy::AnimalProductInterface,
      "LocalProduct" => Dummy::LocalProductInterface,
    }
    result = reduce_types([Dummy::CheeseType])
    assert_equal(expected.keys.sort, result.keys.sort)
    assert_equal(expected, result.to_h)
  end

  it "finds type from arguments" do
    result = reduce_types([Dummy::DairyAppQueryType])
    assert_equal(Dummy::DairyProductInputType, result["DairyProductInput"])
  end

  it "finds types from field instrumentation" do
    type = GraphQL::ObjectType.define do
      name "ArgTypeTest"
      connection :t, type.connection_type
    end

    result = reduce_types([type])
    expected_types = [
      "ArgTypeTest", "ArgTypeTestConnection", "ArgTypeTestEdge",
      "Boolean", "Int", "PageInfo", "String"
    ]
    assert_equal expected_types, result.keys.sort
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

  describe "when getting a type which doesnt exist" do
    it "raises an error" do
      type_map = reduce_types([])
      assert_raises(KeyError) { type_map.fetch("SomeType") }
    end
  end

  describe "when a field is only accessible through an interface" do
    it "is found through Schema.define(types:)" do
      assert_equal Dummy::HoneyType, Dummy::Schema.types["Honey"]
    end
  end
end
