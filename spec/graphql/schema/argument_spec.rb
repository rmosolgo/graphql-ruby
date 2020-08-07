# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Argument do
  module SchemaArgumentTest
    class Query < GraphQL::Schema::Object
      field :field, String, null: true do
        argument :arg, String, description: "test", required: false

        argument :arg_with_block, String, required: false do
          description "test"
        end
        argument :required_with_default_arg, Int, required: true, default_value: 1
        argument :aliased_arg, String, required: false, as: :renamed
        argument :prepared_arg, Int, required: false, prepare: :multiply
        argument :prepared_by_proc_arg, Int, required: false, prepare: ->(val, context) { context[:multiply_by] * val }
        argument :exploding_prepared_arg, Int, required: false, prepare: ->(val, context) do
          raise GraphQL::ExecutionError.new('boom!')
        end

        argument :keys, [String], required: false, method_access: false
        argument :instrument_id, ID, required: false, loads: Jazz::InstrumentType
        argument :instrument_ids, [ID], required: false, loads: Jazz::InstrumentType

        class Multiply
          def call(val, context)
            context[:multiply_by] * val
          end
        end

        argument :prepared_by_callable_arg, Int, required: false, prepare: Multiply.new
      end

      def field(**args)
        # sort the fields so that they match the output of the new interpreter
        sorted_keys = args.keys.sort
        sorted_args = {}
        sorted_keys.each  {|k| sorted_args[k] = args[k] }
        sorted_args.inspect
      end

      def multiply(val)
        context[:multiply_by] * val
      end
    end

    class Schema < GraphQL::Schema
      query(Query)
      lazy_resolve(Proc, :call)
      if TESTING_INTERPRETER
        use GraphQL::Execution::Interpreter
        use GraphQL::Analysis::AST
      end

      def self.object_from_id(id, ctx)
        -> { Jazz::GloballyIdentifiableType.find(id) }
      end

      orphan_types [Jazz::InstrumentType]
    end
  end

  describe "#keys" do
    it "is not overwritten by the 'keys' argument" do
      expected_keys = ["aliasedArg", "arg", "argWithBlock", "explodingPreparedArg", "instrumentId", "instrumentIds", "keys", "preparedArg", "preparedByCallableArg", "preparedByProcArg", "requiredWithDefaultArg"]
      assert_equal expected_keys, SchemaArgumentTest::Query.fields["field"].arguments.keys.sort
    end
  end

  describe "#path" do
    it "includes type, field and argument names" do
      assert_equal "Query.field.argWithBlock", SchemaArgumentTest::Query.fields["field"].arguments["argWithBlock"].path
    end
  end

  describe "#name" do
    it "reflects camelization" do
      assert_equal "argWithBlock", SchemaArgumentTest::Query.fields["field"].arguments["argWithBlock"].name
    end
  end

  describe "#type" do
    let(:argument) { SchemaArgumentTest::Query.fields["field"].arguments["arg"] }
    it "returns the type" do
      assert_equal GraphQL::Types::String, argument.type
    end
  end

  describe "graphql definition" do
    it "calls block" do
      assert_equal "test", SchemaArgumentTest::Query.fields["field"].arguments["argWithBlock"].description
    end
  end

  describe "#description" do
    let(:arg) { SchemaArgumentTest::Query.fields["field"].arguments["arg"] }
    it "sets description" do
      arg.description "new description"
      assert_equal "new description", arg.description
    end

    it "returns description" do
      assert_equal "test", SchemaArgumentTest::Query.fields["field"].arguments["argWithBlock"].description
    end

    it "has an assignment method" do
      arg.description = "another new description"
      assert_equal "another new description", arg.description
    end
  end

  describe "as:" do
    it "uses that Symbol for Ruby kwargs" do
      query_str = <<-GRAPHQL
      { field(aliasedArg: "x") }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str)
      # Make sure it's getting the renamed symbol:
      assert_equal '{:renamed=>"x", :required_with_default_arg=>1}', res["data"]["field"]
    end
  end

  describe "prepare:" do
    it "calls the method on the field's owner" do
      query_str = <<-GRAPHQL
      { field(preparedArg: 5) }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str, context: {multiply_by: 3})
      # Make sure it's getting the renamed symbol:
      assert_equal '{:prepared_arg=>15, :required_with_default_arg=>1}', res["data"]["field"]
    end

    it "calls the method on the provided Proc" do
      query_str = <<-GRAPHQL
      { field(preparedByProcArg: 5) }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str, context: {multiply_by: 3})
      # Make sure it's getting the renamed symbol:
      assert_equal '{:prepared_by_proc_arg=>15, :required_with_default_arg=>1}', res["data"]["field"]
    end

    it "calls the method on the provided callable object" do
      query_str = <<-GRAPHQL
      { field(preparedByCallableArg: 5) }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str, context: {multiply_by: 3})
      # Make sure it's getting the renamed symbol:
      assert_equal '{:prepared_by_callable_arg=>15, :required_with_default_arg=>1}', res["data"]["field"]
    end

    it "handles exceptions raised by prepare" do
      query_str = <<-GRAPHQL
        { f1: field(arg: "echo"), f2: field(explodingPreparedArg: 5) }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str, context: {multiply_by: 3})
      assert_equal({ 'f1' => '{:arg=>"echo", :required_with_default_arg=>1}', 'f2' => nil }, res['data'])
      assert_equal(res['errors'][0]['message'], 'boom!')
      assert_equal(res['errors'][0]['path'], ['f2'])
    end
  end

  describe "default_value:" do
    it 'uses default_value: with no input' do
      query_str = <<-GRAPHQL
      { field }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str)
      assert_equal '{:required_with_default_arg=>1}', res["data"]["field"]
    end

    it 'uses provided input value' do
      query_str = <<-GRAPHQL
      { field(requiredWithDefaultArg: 2) }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str)
      assert_equal '{:required_with_default_arg=>2}', res["data"]["field"]
    end

    it 'respects non-null type' do
      query_str = <<-GRAPHQL
      { field(requiredWithDefaultArg: null) }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str)
      assert_equal "Argument 'requiredWithDefaultArg' on Field 'field' has an invalid value (null). Expected type 'Int!'.", res['errors'][0]['message']
    end
  end

  describe 'loads' do
    it "loads input object arguments" do
      query_str = <<-GRAPHQL
      query { field(instrumentId: "Instrument/Drum Kit") }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str)
      assert_equal "{:instrument=>#{Jazz::Models::Instrument.new("Drum Kit", "PERCUSSION").inspect}, :required_with_default_arg=>1}", res["data"]["field"]

      query_str2 = <<-GRAPHQL
      query { field(instrumentIds: ["Instrument/Organ"]) }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str2)
      assert_equal "{:instruments=>[#{Jazz::Models::Instrument.new("Organ", "KEYS").inspect}], :required_with_default_arg=>1}", res["data"]["field"]
    end

    it "returns nil when no ID is given and `required: false`" do
      query_str = <<-GRAPHQL
      mutation($ensembleId: ID) {
        loadAndReturnEnsemble(input: {ensembleId: $ensembleId}) {
          ensemble {
            name
          }
        }
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str, variables: { ensembleId: "Ensemble/Robert Glasper Experiment" })
      assert_equal "ROBERT GLASPER Experiment", res["data"]["loadAndReturnEnsemble"]["ensemble"]["name"]

      res2 = Jazz::Schema.execute(query_str, variables: { ensembleId: nil })
      assert_nil res2["data"]["loadAndReturnEnsemble"].fetch("ensemble")


      query_str2 = <<-GRAPHQL
      mutation {
        loadAndReturnEnsemble(input: {ensembleId: null}) {
          ensemble {
            name
          }
        }
      }
      GRAPHQL

      res3 = Jazz::Schema.execute(query_str2, variables: { ensembleId: nil })
      assert_nil res3["data"]["loadAndReturnEnsemble"].fetch("ensemble")

      query_str3 = <<-GRAPHQL
      mutation {
        loadAndReturnEnsemble(input: {}) {
          ensemble {
            name
          }
        }
      }
      GRAPHQL

      res4 = Jazz::Schema.execute(query_str3, variables: { ensembleId: nil })
      assert_nil res4["data"]["loadAndReturnEnsemble"].fetch("ensemble")

      query_str4 = <<-GRAPHQL
      query {
        nullableEnsemble(ensembleId: null) {
          name
        }
      }
      GRAPHQL

      res5 = Jazz::Schema.execute(query_str4)
      assert_nil res5["data"].fetch("nullableEnsemble")
    end
  end
end
