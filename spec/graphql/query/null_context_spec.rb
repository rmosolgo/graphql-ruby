# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Query::NullContext do
  class NullContextObjectTest < GraphQL::Schema::Object
    field :thing, String, null: true

    def thing
      object
    end
  end

  it "works with .authorized_new" do
    graphql_obj = NullContextObjectTest.authorized_new(:thing, GraphQL::Query::NullContext)
    graphql_field = NullContextObjectTest.fields.each_value.find { |f| f.original_name == :thing }
    assert_equal :thing, graphql_field.resolve(graphql_obj, {}, graphql_obj.context)
  end
end
