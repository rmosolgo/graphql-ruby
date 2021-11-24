# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema do
  describe "instrumentation teardown bug" do
    # This instrumenter records that it ran,
    # or raises an error if instructed to do so
    class InstrumenterError < StandardError
      attr_reader :key
      def initialize(key)
        @key = key
        super()
      end
    end

    class LogInstrumenter
      def before_query(unit_of_work)
        run_hook(unit_of_work, "begin")
      end

      def after_query(unit_of_work)
        run_hook(unit_of_work, "end")
      end

      alias :before_multiplex :before_query
      alias :after_multiplex :after_query

      private

      def run_hook(unit_of_work, event_name)
        unit_of_work.context[log_key(event_name)] = true
        if unit_of_work.context[raise_key(event_name)]
          raise InstrumenterError.new(log_key(event_name))
        end
      end

      def log_key(event_name)
        context_key("did_#{event_name}")
      end

      def raise_key(event_name)
        context_key("should_raise_#{event_name}")
      end

      def context_key(suffix)
        prefix = self.class.name.sub("Instrumenter", "").downcase
        :"#{prefix}_instrumenter_#{suffix}"
      end
    end

    class FirstInstrumenter < LogInstrumenter; end
    class SecondInstrumenter < LogInstrumenter; end

    class ExecutionErrorInstrumenter
      def before_query(query)
        if query.context[:raise_execution_error]
          raise GraphQL::ExecutionError, "Raised from instrumenter before_query"
        end
      end

      def after_query(query)
      end
    end

    # This is how you might add queries from a persisted query backend

    class QueryStringInstrumenter
      def before_query(query)
        if query.context[:extra_query_string] && query.query_string.nil?
          query.query_string = query.context[:extra_query_string]
        end
      end

      def after_query(query)
      end
    end

    let(:query_type) {
      Class.new(GraphQL::Schema::Object) do
        graphql_name "Query"
        field :int, Integer do
          argument :value, Integer, required: false
        end

        def int(value:)
          value
        end
      end
    }

    let(:schema) {
      spec = self
      Class.new(GraphQL::Schema) do
        query(spec.query_type)
        instrument(:query, FirstInstrumenter.new)
        instrument(:query, SecondInstrumenter.new)
        instrument(:query, ExecutionErrorInstrumenter.new)
        instrument(:query, QueryStringInstrumenter.new)
      end
    }

    describe "query instrumenters" do
      it "before_query of the 2nd instrumenter does not run but after_query does" do
        context = {second_instrumenter_should_raise_begin: true}
        assert_raises InstrumenterError do
          schema.execute(" { int(value: 2) } ", context: context)
        end
        assert context[:first_instrumenter_did_begin]
        assert context[:first_instrumenter_did_end]
        assert context[:second_instrumenter_did_begin]
        refute context[:second_instrumenter_did_end]
      end

      it "runs after_query even if a previous after_query raised an error" do
        context = {second_instrumenter_should_raise_end: true}
        err = assert_raises InstrumenterError do
          schema.execute(" { int(value: 2) } ", context: context)
        end
        # The error came from the second instrumenter:
        assert_equal :second_instrumenter_did_end, err.key
        # But the first instrumenter still got a chance to teardown
        assert context[:first_instrumenter_did_begin]
        assert context[:first_instrumenter_did_end]
        assert context[:second_instrumenter_did_begin]
        assert context[:second_instrumenter_did_end]
      end

      it "rescues execution errors from before_query" do
        context = {raise_execution_error: true}
        res = schema.execute(" { int(value: 2) } ", context: context)
        assert_equal "Raised from instrumenter before_query", res["errors"].first["message"]
        refute res.key?("data"), "The query doesn't run"
      end

      it "can assign a query string there" do
        context = { extra_query_string: "{ __typename }"}
        res = schema.execute(nil, context: context)
        assert_equal "Query", res["data"]["__typename"]
      end
    end

    describe "within a multiplex" do
      let(:multiplex_schema) {
        Class.new(schema) {
          instrument(:multiplex, FirstInstrumenter.new)
          instrument(:multiplex, SecondInstrumenter.new)
        }
      }

      it "only runs after_multiplex if before_multiplex finished" do
        multiplex_ctx = {second_instrumenter_should_raise_begin: true}
        query_1_ctx = {}
        query_2_ctx = {}
        assert_raises InstrumenterError do
          multiplex_schema.multiplex(
            [
              {query: "{int(value: 1)}", context: query_1_ctx},
              {query: "{int(value: 2)}", context: query_2_ctx},
            ],
            context: multiplex_ctx
          )
        end

        assert multiplex_ctx[:first_instrumenter_did_begin]
        assert multiplex_ctx[:first_instrumenter_did_end]
        assert multiplex_ctx[:second_instrumenter_did_begin]
        refute multiplex_ctx[:second_instrumenter_did_end]
        # No query instrumentation was run at all
        assert_equal 0, query_1_ctx.size
        assert_equal 0, query_2_ctx.size
      end

      it "does full and partial query runs" do
        multiplex_ctx = {}
        query_1_ctx = {}
        query_2_ctx = {second_instrumenter_should_raise_begin: true}
        assert_raises InstrumenterError do
          multiplex_schema.multiplex(
            [
              { query: " { int(value: 2) } ", context: query_1_ctx },
              { query: " { int(value: 2) } ", context: query_2_ctx },
            ],
            context: multiplex_ctx
          )
        end

        # multiplex got a full run
        assert multiplex_ctx[:first_instrumenter_did_begin]
        assert multiplex_ctx[:first_instrumenter_did_end]
        assert multiplex_ctx[:second_instrumenter_did_begin]
        assert multiplex_ctx[:second_instrumenter_did_end]

        # query 1 got a full run
        assert query_1_ctx[:first_instrumenter_did_begin]
        assert query_1_ctx[:first_instrumenter_did_end]
        assert query_1_ctx[:second_instrumenter_did_begin]
        assert query_1_ctx[:second_instrumenter_did_end]

        # query 2 got a partial run
        assert query_2_ctx[:first_instrumenter_did_begin]
        assert query_2_ctx[:first_instrumenter_did_end]
        assert query_2_ctx[:second_instrumenter_did_begin]
        refute query_2_ctx[:second_instrumenter_did_end]
      end
    end
  end
end
