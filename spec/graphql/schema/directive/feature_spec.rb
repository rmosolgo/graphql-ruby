# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Directive::Feature do
  class FeatureSchema < GraphQL::Schema
    class Feature < GraphQL::Schema::Directive::Feature
      def self.enabled?(flag_name, obj, ctx)
        !!ctx[flag_name.to_sym]
      end
    end

    class Query < GraphQL::Schema::Object
      field :int, Integer, null: false

      def int
        context[:int] ||= 0
        context[:int] += 1
      end
    end

    directive(Feature)
    query(Query)
  end


  it "skips or runs fields" do
    str = '{
      int1: int
      int2: int @feature(flag: "flag1")
      int3: int @feature(flag: "flag2")
    }'

    res = FeatureSchema.execute(str, context: { flag2: true })
    # Int2 was not called, so `int3` is actually 2
    assert_equal({"int1" => 1, "int3" => 2}, res["data"])
  end

  it "skips or runs fragment spreads" do
    str = '{
      ...F1
      ...F2 @feature(flag: "flag1")
      ...F3 @feature(flag: "flag2")
      int4: int
    }

    fragment F1 on Query { int1: int }
    fragment F2 on Query { int2: int }
    fragment F3 on Query { int3: int }
    '

    res = FeatureSchema.execute(str, context: { flag1: true })
    # `int3` was skipped
    assert_equal({"int1" => 1, "int2" => 2, "int4" => 3}, res["data"])
  end
  it "skips or runs inline fragments" do
    str = '{
      ... { int1: int }
      ... @feature(flag: "flag1") { int2: int }
      ... @feature(flag: "flag2") { int3: int }
      int4: int
    }
    '

    res = FeatureSchema.execute(str, context: { flag2: true })
    # `int2` was skipped
    assert_equal({"int1" => 1, "int3" => 2, "int4" => 3}, res["data"])
  end

  it "returns an error if it's in the wrong place" do
    str = '
    query @feature(flag: "x") {
      int
    }
    '
    res = FeatureSchema.execute(str)
    assert_equal ["'@feature' can't be applied to queries (allowed: fields, fragment spreads, inline fragments)"], res["errors"].map { |e| e["message"] }
  end
end
