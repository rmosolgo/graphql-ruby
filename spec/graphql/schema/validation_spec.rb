# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Validation do
  def assert_error_includes(object, error_substring)
    validation_error = GraphQL::Schema::Validation.validate(object)
    assert_includes validation_error, error_substring
  end

  describe "validating Fields" do
    let(:unnamed_field) {
      GraphQL::Field.define do
        type GraphQL::STRING_TYPE
      end
    }

    let(:invalid_name_field) {
      GraphQL::Field.define do
        name "__Something"
        type GraphQL::STRING_TYPE
      end
    }

    let(:untyped_field) {
      GraphQL::Field.define do
        name "Untyped"
        type :something_invalid
      end
    }

    let(:bad_arguments_field) {
      field = GraphQL::Field.define do
        name "BadArgs"
        type !GraphQL::BOOLEAN_TYPE
      end
      field.arguments[:bad_key] = :bad_value
      field
    }

    let(:invalid_argument_member_field) {
      GraphQL::Field.define do
        name "InvalidArgument"
        type !types[!GraphQL::INT_TYPE]
        argument :invalid do
          type GraphQL::FLOAT_TYPE
          default_value [1,2,3]
        end
      end
    }

    it "requires a String for name" do
      assert_error_includes unnamed_field, "must return String, not NilClass"
    end

    it "cannot use reserved name" do
      assert_error_includes invalid_name_field, 'Name "__Something" must not begin with "__", which is reserved by GraphQL introspection.'
    end

    it "requires a BaseType for type" do
      assert_error_includes untyped_field, "must return GraphQL::BaseType, not Symbol"
    end

    it "requires String => Argument arguments" do
      assert_error_includes bad_arguments_field, "must map String => GraphQL::Argument, not Symbol => Symbol"
    end

    it "applies validation to its member Arguments" do
      assert_error_includes invalid_argument_member_field, "default value [1, 2, 3] is not valid for type Float"
    end
  end

  describe "validating BaseType" do
    let(:unnamed_type) {
      GraphQL::BaseType.define do
        name :invalid_name
      end
    }

    let(:invalid_name_type) {
      GraphQL::BaseType.define do
        name '__Something'
      end
    }

    let(:wrongly_described_type) {
      GraphQL::BaseType.define do
        name "WronglyDescribed"
        description 12345
      end
    }

    it "requires a String name" do
      assert_error_includes unnamed_type, "must return String, not Symbol"
    end

    it "cannot use reserved name" do
      assert_error_includes invalid_name_type, 'Name "__Something" must not begin with "__", which is reserved by GraphQL introspection.'
    end

    it "requires String-or-nil description" do
      assert_error_includes wrongly_described_type, "must return String or NilClass, not Fixnum"
    end
  end

  describe "validating ObjectTypes" do
    let(:invalid_interfaces_object) {
      GraphQL::ObjectType.define do
        name "InvalidInterfaces"
        interfaces(55)
      end
    }

    let(:invalid_interface_member_object) {
      GraphQL::ObjectType.define do
        name "InvalidInterfaceMember"
        interfaces [:not_an_interface]
      end
    }

    let(:invalid_field_object) {
      GraphQL::ObjectType.define do
        name "InvalidField"
        field :invalid, :nonsense
      end
    }

    it "requires an Array for interfaces" do
      assert_error_includes invalid_interfaces_object, "must be an Array of GraphQL::InterfaceType, not a Fixnum"
      assert_error_includes invalid_interface_member_object, "must contain GraphQL::InterfaceType, not Symbol"
    end

    it "validates the fields" do
      assert_error_includes invalid_field_object, "must return GraphQL::BaseType, not Symbol"
    end
  end

  describe "validating UnionTypes" do
    let(:non_array_union) {
      GraphQL::UnionType.define do
        name "NonArray"
        possible_types 55
      end
    }

    let(:non_object_type_union) {
      GraphQL::UnionType.define do
        name "NonObjectTypes"
        possible_types [
          GraphQL::InterfaceType.new
        ]
      end
    }

    let(:no_possible_types_union) {
      GraphQL::UnionType.define do
        name "NoPossibleTypes"
        possible_types []
      end
    }

    it "requires an array of ObjectTypes for possible_types" do
      assert_error_includes non_array_union, "must be an Array of GraphQL::ObjectType, not a Fixnum"

      assert_error_includes non_object_type_union, "must contain GraphQL::ObjectType, not GraphQL::InterfaceType"
    end

    it "requires at least one possible_types" do
      assert_error_includes no_possible_types_union, "must have at least one possible type"
    end
  end

  describe "validating InputObjectTypes" do
    let(:invalid_arguments_input) {
      input = GraphQL::InputObjectType.define do
        name "InvalidArgumentsHash"
      end
      input.arguments[123] = :nonsense
      input
    }

    let(:invalid_argument_member_input) {
      GraphQL::InputObjectType.define do
        name "InvalidArgumentMember"
        argument :nonsense do
          type GraphQL::FLOAT_TYPE
          default_value ["xyz"]
        end
      end
    }

    it "requires {String => Argument} arguments" do
      assert_error_includes invalid_arguments_input, "map String => GraphQL::Argument, not Fixnum => Symbol"
    end

    it "applies validation to its member Arguments" do
      assert_error_includes invalid_argument_member_input, "default value [\"xyz\"] is not valid for type Float"
    end
  end

  describe "validating InterfaceTypes" do
    let(:invalid_field_interface) {
      GraphQL::InterfaceType.define do
        name "InvalidField"
        field :invalid do
          type GraphQL::BOOLEAN_TYPE
          argument :invalid do
            type GraphQL::FLOAT_TYPE
            default_value ["123"]
          end
        end
      end
    }

    it "validates fields" do
      assert_error_includes invalid_field_interface, "default value [\"123\"] is not valid for type Float"
    end
  end

  describe "validating Arguments" do
    let(:untyped_argument) {
      GraphQL::Argument.define do
        name "Untyped"
        type :Bogus
      end
    }

    let(:invalid_default_argument_for_non_null_argument) {
      GraphQL::Argument.define do
        name "InvalidDefault"
        type !GraphQL::INT_TYPE
        default_value 1
      end
    }

    let(:invalid_name_argument) {
      GraphQL::Argument.define do
        name "__Something"
        type GraphQL::INT_TYPE
      end
    }

    let(:null_default_value) {
      GraphQL::Argument.define do
        name "NullDefault"
        type DairyAnimalEnum
        default_value nil
      end
    }

    it "requires the type is a Base type" do
      assert_error_includes untyped_argument, "must be a valid input type (Scalar or InputObject), not Symbol"
    end

    it "does not allow default values for non-null argument" do
      assert_error_includes invalid_default_argument_for_non_null_argument, 'Variable InvalidDefault of type "Int!" is required and will not use the default value. Perhaps you meant to use type "Int".'
    end

    it "cannot use reserved name" do
      assert_error_includes invalid_name_argument, 'Name "__Something" must not begin with "__", which is reserved by GraphQL introspection.'
    end

    it "allows null default value for nullable argument" do
      assert_equal nil, GraphQL::Schema::Validation.validate(null_default_value)
    end
  end
end
