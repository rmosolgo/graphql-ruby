# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Member::TypeSystemHelpers do
  let(:object) {
    Class.new(GraphQL::Schema::Object) do
      graphql_name "Thing"

      field :int, Integer, null: true
      field :int2, Integer, null: false
      field :int_list, [Integer], null: true
      field :int_list2, [Integer], null: false
    end
  }

  let(:int_field) { object.fields["int"] }
  let(:int2_field) { object.fields["int2"] }
  let(:int_list_field) { object.fields["intList"] }
  let(:int_list2_field) { object.fields["intList2"] }

  describe "#list?" do
    it "is true for lists, including non-null lists, otherwise false" do
      assert int_list_field.type.list?
      assert int_list2_field.type.list?
      refute int_field.type.list?
      refute int2_field.type.list?
    end
  end

  describe "#non_null?" do
    it "is true for required types" do
      assert int2_field.type.non_null?
      assert int_list2_field.type.non_null?
      refute int_field.type.non_null?
      refute int_list_field.type.non_null?
    end
  end
end
