# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema do
  describe "instrumentation teardown bug" do
    class BadInstrumenter
      def before_query(query)
        query.context[:bad_instrumenter_did_begin] = true
        self.bad_method # raises NoMethodError
      end

      def after_query(query)
        query.context[:bad_instrumenter_did_end] = true
      end
    end

    class GoodInstrumenter
      def before_query(query)
        query.context[:good_instrumenter_did_begin] = true
      end

      def after_query(query)
        query.context[:good_instrumenter_did_end] = true
      end
    end

    let(:query_type) {
      GraphQL::ObjectType.define do
        name "Query"
        field :int, types.Int do
          argument :value, types.Int
          resolve ->(obj, args, ctx) { args.value }
        end
      end
    }

    let(:schema) {
      spec = self
      GraphQL::Schema.define do
        query(spec.query_type)
        instrument(:query, GoodInstrumenter.new)
        instrument(:query, BadInstrumenter.new)
      end
    }

    it "before_query of the 2nd instrumenter does not run but after_query does" do
      context = {}
      assert_raises NoMethodError do
        schema.execute(" { int(value: 2) } ", context: context)
      end

      assert context[:good_instrumenter_did_begin]
      assert context[:good_instrumenter_did_end]
      assert context[:bad_instrumenter_did_begin]
      refute context[:bad_instrumenter_did_end]
    end
  end
end
