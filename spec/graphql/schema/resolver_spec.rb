# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Resolver do
  module ResolverTest
    class BaseResolver < GraphQL::Schema::Resolver
    end

    class Resolver1 < BaseResolver
      argument :value, Integer, required: false
      type [Integer, null: true], null: false

      def initialize(object:, context:)
        super
        if defined?(@value)
          raise "The instance should start fresh"
        end
        @value = [100]
      end

      def resolve(value: nil)
        @value << value
        @value
      end
    end

    class Resolver2 < Resolver1
      argument :extra_value, Integer, required: true

      def resolve(extra_value:, **_rest)
        value = super(_rest)
        value << extra_value
        value
      end
    end

    class Resolver3 < Resolver1
      class CustomField < GraphQL::Schema::Field
        def resolve_field(*args)
          value = super
          value << -1
          value
        end
      end

      field_class(CustomField)
    end


    class Query < GraphQL::Schema::Object
      field :resolver_1, resolver: Resolver1
      field :resolver_2, resolver: Resolver2
      field :resolver_3, resolver: Resolver3
    end

    class Schema < GraphQL::Schema
      query(Query)
    end
  end

  it "gets initialized for each resolution" do
    # State isn't shared between calls:
    res = ResolverTest::Schema.execute " { r1: resolver1(value: 1) r2: resolver1 }"
    assert_equal [100, 1], res["data"]["r1"]
    assert_equal [100, nil], res["data"]["r2"]
  end

  it "inherits type and arguments" do
    res = ResolverTest::Schema.execute " { r1: resolver2(value: 1, extraValue: 2) r2: resolver2(extraValue: 3) }"
    assert_equal [100, 1, 2], res["data"]["r1"]
    assert_equal [100, nil, 3], res["data"]["r2"]
  end

  it "uses a custom field_class" do
    res = ResolverTest::Schema.execute " { r1: resolver3(value: 1) r2: resolver3 }"
    assert_equal [100, 1, -1], res["data"]["r1"]
    assert_equal [100, nil, -1], res["data"]["r2"]
  end
end
