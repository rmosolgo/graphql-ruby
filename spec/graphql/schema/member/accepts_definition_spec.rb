# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Member::AcceptsDefinition do
  class AcceptsDefinitionSchema < GraphQL::Schema
    accepts_definition :set_metadata
    set_metadata :a, 999

    class Option < GraphQL::Schema::Enum
      class EnumValue < GraphQL::Schema::EnumValue
        accepts_definition :metadata
      end
      enum_value_class EnumValue
      accepts_definition :metadata
      metadata :a, 123
      value "A", metadata: [:a, 456]
      value "B"
    end

    class Query < GraphQL::Schema::Object
      class Field < GraphQL::Schema::Field
        class Argument < GraphQL::Schema::Argument
          accepts_definition :metadata
        end
        argument_class Argument
        accepts_definition :metadata
      end
      field_class Field
      accepts_definition :metadata
      metadata :a, :abc

      field :option, Option, null: false do
        metadata :a, :def
        argument :value, Integer, required: true, metadata: [:a, :ghi]
      end
    end

    query(Query)
  end


  it "passes along configs for types" do
    assert_equal [:a, 123], AcceptsDefinitionSchema::Option.metadata
    assert_equal 123, AcceptsDefinitionSchema::Option.graphql_definition.metadata[:a]
    assert_equal [:a, :abc], AcceptsDefinitionSchema::Query.metadata
    assert_equal :abc, AcceptsDefinitionSchema::Query.graphql_definition.metadata[:a]
  end

  it "passes along configs for fields and arguments" do
    assert_equal :def, AcceptsDefinitionSchema.find("Query.option").metadata[:a]
    assert_equal :ghi, AcceptsDefinitionSchema.find("Query.option.value").metadata[:a]
  end

  it "passes along configs for enum values" do
    assert_equal 456, AcceptsDefinitionSchema.find("Option.A").metadata[:a]
    assert_nil AcceptsDefinitionSchema.find("Option.B").metadata[:a]
  end

  it "passes along configs for schemas" do
    assert_equal 999, AcceptsDefinitionSchema.graphql_definition.metadata[:a]
  end
end
