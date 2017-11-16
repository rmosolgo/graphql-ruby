# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema do
  describe "instrumentation teardown bug" do
    class BadInstrumenter
      def before_query(query)
        bad_method
      end

      def after_query(query)
      end
    end

    class GoodInstrumenter
      attr_reader :before_query_did_run

      def before_query(query)
        @before_query_did_run = true
      end

      def after_query(query)
        raise 'bad teardown' unless before_query_did_run
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
        instrument(:query, BadInstrumenter.new)
        instrument(:query, GoodInstrumenter.new)
      end
    }

    it "before_query of the 2nd instrumenter does not run but after_query does" do
      res = schema.execute(" { int(value: 2) } ")
      assert_equal 2, res["data"]["int"]
    end
  end
end
