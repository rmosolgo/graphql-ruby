# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema do
  describe "instrumentation teardown bug" do
    class BadInstrumenter
      def before_query(unit_of_work)
        unit_of_work.context[:bad_instrumenter_did_begin] = true
        if !unit_of_work.context[:skip_bad_method]
          self.bad_method # raises NoMethodError
        end
      end

      def after_query(unit_of_work)
        unit_of_work.context[:bad_instrumenter_did_end] = true
      end
      alias :before_multiplex :before_query
      alias :after_multiplex :after_query
    end

    class GoodInstrumenter
      def before_query(unit_of_work)
        unit_of_work.context[:good_instrumenter_did_begin] = true
      end

      def after_query(unit_of_work)
        unit_of_work.context[:good_instrumenter_did_end] = true
      end
      alias :before_multiplex :before_query
      alias :after_multiplex :after_query
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

    describe "query instrumenters" do
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

    describe "within a multiplex" do
      let(:multiplex_schema) {
        schema.redefine {
          instrument(:multiplex, GoodInstrumenter.new)
          instrument(:multiplex, BadInstrumenter.new)
        }
      }

      it "only runs after_multiplex if before_multiplex finished" do
        multiplex_ctx = {}
        query_1_ctx = {}
        query_2_ctx = {}
        assert_raises NoMethodError do
          multiplex_schema.multiplex(
            [
              {query: "{int(value: 1)}", context: query_1_ctx},
              {query: "{int(value: 2)}", context: query_2_ctx},
            ],
            context: multiplex_ctx
          )
        end

        assert multiplex_ctx[:good_instrumenter_did_begin]
        assert multiplex_ctx[:good_instrumenter_did_end]
        assert multiplex_ctx[:bad_instrumenter_did_begin]
        refute multiplex_ctx[:bad_instrumenter_did_end]
        # No query instrumentation was run at all
        assert_equal 0, query_1_ctx.size
        assert_equal 0, query_2_ctx.size
      end

      it "does full and partial query runs" do
        multiplex_ctx = {skip_bad_method: true}
        query_1_ctx = {skip_bad_method: true}
        query_2_ctx = {}
        assert_raises NoMethodError do
          multiplex_schema.multiplex(
            [
              { query: " { int(value: 2) } ", context: query_1_ctx },
              { query: " { int(value: 2) } ", context: query_2_ctx },
            ],
            context: multiplex_ctx
          )
        end

        # multiplex got a full run
        assert multiplex_ctx[:good_instrumenter_did_begin]
        assert multiplex_ctx[:good_instrumenter_did_end]
        assert multiplex_ctx[:bad_instrumenter_did_begin]
        assert multiplex_ctx[:bad_instrumenter_did_end]

        # query 1 got a full run
        assert query_1_ctx[:good_instrumenter_did_begin]
        assert query_1_ctx[:good_instrumenter_did_end]
        assert query_1_ctx[:bad_instrumenter_did_begin]
        assert query_1_ctx[:bad_instrumenter_did_end]

        # query 2 got a partial run
        assert query_2_ctx[:good_instrumenter_did_begin]
        assert query_2_ctx[:good_instrumenter_did_end]
        assert query_2_ctx[:bad_instrumenter_did_begin]
        refute query_2_ctx[:bad_instrumenter_did_end]
      end
    end
  end
end
