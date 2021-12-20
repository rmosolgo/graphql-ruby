# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Member::AcceptsDefinition do
  class AcceptsDefinitionSchema < GraphQL::Schema
    accepts_definition :set_metadata
    set_metadata :a, 999

    class BaseField < GraphQL::Schema::Field
      class BaseField < GraphQL::Schema::Argument
        accepts_definition :metadata
      end
      argument_class BaseField
      accepts_definition :metadata
    end

    GraphQL::Schema::Object.accepts_definition(:metadata2)

    class BaseObject < GraphQL::Schema::Object
      field_class BaseField
      accepts_definition :metadata
    end

    GraphQL::Schema::Interface.accepts_definition(:metadata2)

    module BaseInterface
      include GraphQL::Schema::Interface
      field_class BaseField
      accepts_definition :metadata
    end

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

    module Thing
      include BaseInterface
      metadata :z, 888
      metadata2 :a, :bc
    end

    module Thing2
      include Thing
    end

    class SomeObject < BaseObject
      metadata :a, :aaa

      field :some_field, String
    end

    class SomeObject2 < SomeObject
    end

    class Query < BaseObject
      metadata :a, :abc
      metadata2 :xyz, :zyx

      field :option, Option, null: false do
        metadata :a, :def
        argument :value, Integer, metadata: [:a, :ghi]
      end

      field :thing, Thing, null: false
      field :thing2, Thing2, null: false
      field :some_object, SomeObject, null: false
      field :some_object2, SomeObject2, null: false
    end

    query(Query)
  end

  it "passes along configs for types" do
    assert_equal [:a, 123], AcceptsDefinitionSchema::Option.metadata
    assert_equal 123, AcceptsDefinitionSchema::Option.graphql_definition(silence_deprecation_warning: true).metadata[:a]
    assert_equal [:a, :abc], AcceptsDefinitionSchema::Query.metadata
    assert_equal :abc, AcceptsDefinitionSchema::Query.graphql_definition(silence_deprecation_warning: true).metadata[:a]
    assert_equal :zyx, AcceptsDefinitionSchema::Query.graphql_definition(silence_deprecation_warning: true).metadata[:xyz]

    assert_equal [:z, 888], AcceptsDefinitionSchema::Thing.metadata
    assert_equal 888, AcceptsDefinitionSchema::Thing.graphql_definition(silence_deprecation_warning: true).metadata[:z]
    assert_equal :bc, AcceptsDefinitionSchema::Thing.graphql_definition(silence_deprecation_warning: true).metadata[:a]
    # Interface inheritance
    assert_equal [:z, 888], AcceptsDefinitionSchema::Thing2.metadata
    assert_equal 888, AcceptsDefinitionSchema::Thing2.graphql_definition(silence_deprecation_warning: true).metadata[:z]
    assert_equal :bc, AcceptsDefinitionSchema::Thing2.graphql_definition(silence_deprecation_warning: true).metadata[:a]

    # Object inheritance
    assert_equal :aaa, AcceptsDefinitionSchema::SomeObject.graphql_definition(silence_deprecation_warning: true).metadata[:a]
    assert_equal :aaa, AcceptsDefinitionSchema::SomeObject2.graphql_definition(silence_deprecation_warning: true).metadata[:a]
  end

  it "passes along configs for fields and arguments" do
    assert_equal :def, AcceptsDefinitionSchema.find("Query.option").graphql_definition(silence_deprecation_warning: true).metadata[:a]
    assert_equal :ghi, AcceptsDefinitionSchema.find("Query.option.value").graphql_definition(silence_deprecation_warning: true).metadata[:a]
  end

  it "passes along configs for enum values" do
    assert_equal 456, AcceptsDefinitionSchema.find("Option").graphql_definition(silence_deprecation_warning: true).values["A"].metadata[:a]
    assert_nil AcceptsDefinitionSchema.find("Option").graphql_definition(silence_deprecation_warning: true).values["B"].metadata[:a]
  end

  it "passes along configs for schemas" do
    assert_equal 999, AcceptsDefinitionSchema.graphql_definition(silence_deprecation_warning: true).metadata[:a]
  end
end
