# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::InputObject do
  let(:input_object) { Jazz::EnsembleInput }

  describe ".path" do
    it "is the name" do
      assert_equal "EnsembleInput", input_object.path
    end

    it "is used in argument paths" do
      assert_equal "EnsembleInput.name", input_object.arguments["name"].path
    end
  end

  describe "type info" do
    it "has it" do
      assert_equal "EnsembleInput", input_object.graphql_name
      assert_equal nil, input_object.description
      assert_equal 1, input_object.arguments.size
    end

    it "is the #owner of its arguments" do
      argument = input_object.arguments["name"]
      assert_equal input_object, argument.owner
    end

    it "inherits arguments" do
      base_class = Class.new(GraphQL::Schema::InputObject) do
        argument :arg1, String, required: true
        argument :arg2, String, required: true
      end

      subclass = Class.new(base_class) do
        argument :arg2, Integer, required: true
        argument :arg3, Integer, required: true
      end

      ensemble_class = Class.new(subclass) do
        argument :ensemble_id, GraphQL::Types::ID, required: false, loads: Jazz::Ensemble
      end

      assert_equal 3, subclass.arguments.size
      assert_equal ["arg1", "arg2", "arg3"], subclass.arguments.keys
      assert_equal ["String!", "Int!", "Int!"], subclass.arguments.values.map { |a| a.type.to_type_signature }
      assert_equal ["String!", "Int!", "Int!", "ID"], ensemble_class.arguments.values.map { |a| a.type.to_type_signature }
      assert_equal :ensemble, ensemble_class.arguments["ensembleId"].keyword
    end
  end

  describe ".to_graphql" do
    it "assigns itself as the arguments_class" do
      assert_equal input_object, input_object.to_graphql.arguments_class
    end

    it "accepts description: kwarg" do
      input_obj_class = Jazz::InspectableInput
      input_obj_type = input_obj_class.to_graphql
      assert_equal "Test description kwarg", input_obj_type.arguments["stringValue"].description
    end
  end

  describe "camelizing with numbers" do
    module InputObjectWithNumbers
      class InputObject < GraphQL::Schema::InputObject
        argument :number_arg1, Integer, required: false
        argument :number_arg_2, Integer, required: false
        argument :number_arg3, Integer, required: false, camelize: false
        argument :number_arg_4, Integer, required: false, camelize: false
        argument :numberArg5, Integer, required: false
        argument :numberArg6, Integer, required: false, camelize: false
      end
    end

    it "accepts leading underscores or _no_ underscores" do
      input_obj = InputObjectWithNumbers::InputObject
      assert_equal ["numberArg1", "numberArg2", "number_arg3", "number_arg_4", "numberArg5", "numberArg6"], input_obj.arguments.keys
      assert_equal ["numberArg1", "numberArg2", "number_arg3", "number_arg_4", "numberArg5", "numberArg6"], input_obj.arguments.values.map(&:graphql_name)
      assert_equal :number_arg1, input_obj.arguments["numberArg1"].keyword
      assert_equal :number_arg_2, input_obj.arguments["numberArg2"].keyword
      assert_equal :number_arg3, input_obj.arguments["number_arg3"].keyword
      assert_equal :number_arg_4, input_obj.arguments["number_arg_4"].keyword
      assert_equal :numberArg5, input_obj.arguments["numberArg5"].keyword
      assert_equal :numberArg6, input_obj.arguments["numberArg6"].keyword
    end
  end

  describe "prepare with camelized inputs" do
    class PrepareCamelizedSchema < GraphQL::Schema
      class CamelizedInput < GraphQL::Schema::InputObject
        argument :inputString, String, required: true,
          camelize: false,
          as: :input_string,
          prepare: ->(val, ctx) { val.upcase }
      end

      class Query < GraphQL::Schema::Object
        field :input_test, String, null: false do
          argument :camelized_input, CamelizedInput, required: true
        end

        def input_test(camelized_input:)
          camelized_input[:input_string]
        end
      end

      query(Query)
      if TESTING_INTERPRETER
        use GraphQL::Execution::Interpreter
        use GraphQL::Analysis::AST
      end
    end

    it "calls the prepare proc" do
      res = PrepareCamelizedSchema.execute("{ inputTest(camelizedInput: { inputString: \"abc\" }) }")
      assert_equal "ABC", res["data"]["inputTest"]
    end
  end

  describe "prepare: / loads: / as:" do
    module InputObjectPrepareTest
      class InputObj < GraphQL::Schema::InputObject
        argument :a, Integer, required: true
        argument :b, Integer, required: true, as: :b2
        argument :c, Integer, required: true, prepare: :prep
        argument :d, Integer, required: true, prepare: :prep, as: :d2
        argument :e, Integer, required: true, prepare: ->(val, ctx) { val * ctx[:multiply_by] * 2 }, as: :e2
        argument :instrument_id, ID, required: true, loads: Jazz::InstrumentType
        argument :danger, Integer, required: false, prepare: ->(val, ctx) { raise GraphQL::ExecutionError.new('boom!') }

        def prep(val)
          val * context[:multiply_by]
        end
      end

      class Query < GraphQL::Schema::Object
        field :inputs, [String], null: false do
          argument :input, InputObj, required: true
        end

        def inputs(input:)
          [input.to_kwargs.inspect, input.instrument.name]
        end
      end

      class Mutation < GraphQL::Schema::Object
        class InstrumentInput < GraphQL::Schema::InputObject
          argument :instrument_id, ID, required: true, loads: Jazz::InstrumentType
        end

        class TouchInstrument < GraphQL::Schema::Mutation
          argument :input_obj, InstrumentInput, required: true
          field :instrument_name_method, String, null: false
          field :instrument_name_key, String, null: false

          def resolve(input_obj:)
            # Make sure both kinds of access work the same:
            {
              instrument_name_method: input_obj.instrument.name,
              instrument_name_key: input_obj[:instrument].name,
            }
          end
        end

        field :touch_instrument, mutation: TouchInstrument

        class ListInstruments < GraphQL::Schema::Mutation
          argument :list, [InstrumentInput], required: true
          field :resolved_list, String, null: false

          def resolve(list:)
            {
              resolved_list: list.map(&:to_kwargs).inspect
            }
          end
        end

        field :list_instruments, mutation: ListInstruments
      end


      class Schema < GraphQL::Schema
        query(Query)
        mutation(Mutation)
        lazy_resolve(Proc, :call)
        if TESTING_INTERPRETER
          use GraphQL::Execution::Interpreter
          use GraphQL::Analysis::AST
        end

        def self.object_from_id(id, ctx)
          -> { Jazz::GloballyIdentifiableType.find(id) }
        end

        def self.resolve_type(type, obj, ctx)
          type
        end

        orphan_types [Jazz::InstrumentType]
        max_complexity 100
      end
    end

    it "calls methods on the input object" do
      query_str = <<-GRAPHQL
      { inputs(input: { a: 1, b: 2, c: 3, d: 4, e: 5, instrumentId: "Instrument/Drum Kit" }) }
      GRAPHQL

      res = InputObjectPrepareTest::Schema.execute(query_str, context: { multiply_by: 3 })
      expected_obj = [{ a: 1, b2: 2, c: 9, d2: 12, e2: 30, instrument: Jazz::Models::Instrument.new("Drum Kit", "PERCUSSION") }.inspect, "Drum Kit"]
      assert_equal expected_obj, res["data"]["inputs"]
    end

    it "handles exceptions preparing variable input objects" do
      query_str = <<-GRAPHQL
      query($input: InputObj!){ inputs(input: $input) }
      GRAPHQL

      input = { "a" => 1, "b" => 2, "c" => 3, "d" => 4, "e" => 5, "instrumentId" => "Instrument/Drum Kit", "danger" => 1 }
      res = InputObjectPrepareTest::Schema.execute(query_str, context: { multiply_by: 3 },
                                                   variables: { input: input})
      assert_nil(res["data"])

      if TESTING_INTERPRETER
        assert_equal("boom!", res["errors"][0]["message"])
        assert_equal([{ "line" => 1, "column" => 33 }], res["errors"][0]["locations"])
      else
        assert_equal("Variable $input of type InputObj! was provided invalid value", res["errors"][0]["message"])
        assert_equal([{ "line" => 1, "column" => 13 }], res["errors"][0]["locations"])
        assert_equal("boom!", res["errors"][0]["extensions"]["problems"][0]["explanation"])
        assert_equal(input, res["errors"][0]["extensions"]["value"])
      end
    end

    it "handles not-found with max complexity analyzer running" do
      query_str = <<-GRAPHQL
      { inputs(input: {a: 1, b: 2, c: 3, d: 4, e: 6, instrumentId: "Instrument/Nonsense"}) }
      GRAPHQL

      res = InputObjectPrepareTest::Schema.execute(
        query_str,
        context: { multiply_by: 3 }
      )

      assert_equal ["No object found for `instrumentId: \"Instrument/Nonsense\"`"], res["errors"].map { |e| e["message"] }
    end

    it "loads input object arguments" do
      query_str = <<-GRAPHQL
      mutation {
        touchInstrument(inputObj: { instrumentId: "Instrument/Drum Kit" }) {
          instrumentNameMethod
          instrumentNameKey
        }
      }
      GRAPHQL

      res = InputObjectPrepareTest::Schema.execute(query_str)
      assert_equal "Drum Kit", res["data"]["touchInstrument"]["instrumentNameMethod"]
      assert_equal "Drum Kit", res["data"]["touchInstrument"]["instrumentNameKey"]
    end

    it "loads nested input object arguments" do
      query_str = <<-GRAPHQL
      mutation {
        listInstruments(list: [{ instrumentId: "Instrument/Drum Kit" }]) {
          resolvedList
        }
      }
      GRAPHQL

      res = InputObjectPrepareTest::Schema.execute(query_str)
      expected_obj = [{ instrument: Jazz::Models::Instrument.new("Drum Kit", "PERCUSSION") }].inspect
      assert_equal expected_obj, res["data"]["listInstruments"]["resolvedList"]
    end
  end

  describe "prepare (entire input object)" do
    module InputObjectPrepareObjectTest
      class InputObj < GraphQL::Schema::InputObject
        argument :min, Integer, required: true
        argument :max, Integer, required: false

        def prepare
          min..max
        end
      end

      class Query < GraphQL::Schema::Object
        field :inputs, String, null: false do
          argument :input, InputObj, required: true
        end

        def inputs(input:)
          input.inspect
        end
      end

      class Schema < GraphQL::Schema
        query(Query)

        if TESTING_INTERPRETER
          use GraphQL::Execution::Interpreter
          use GraphQL::Analysis::AST
        end
      end
    end

    it "calls prepare on the input object (literal)" do
      query_str = <<-GRAPHQL
      { inputs(input: { min: 5, max: 10 }) }
      GRAPHQL

      res = InputObjectPrepareObjectTest::Schema.execute(query_str)
      expected_obj = (5..10).inspect
      assert_equal expected_obj, res["data"]["inputs"]
    end

    it "calls prepare on the input object (variable)" do
      query_str = <<-GRAPHQL
      query ($input: InputObj!){ inputs(input: $input) }
      GRAPHQL

      res = InputObjectPrepareObjectTest::Schema.execute(query_str, variables: { input: { min: 5, max: 10 } })
      expected_obj = (5..10).inspect
      assert_equal expected_obj, res["data"]["inputs"]
    end
  end

  describe "loading application object(s)" do
    module InputObjectLoadsTest
      class BaseArgument < GraphQL::Schema::Argument
        def authorized?(obj, val, ctx)
          if contains_spinal_tap?(val)
            false
          else
            true
          end
        end

        def contains_spinal_tap?(val)
          if val.is_a?(Array)
            val.any? { |v| contains_spinal_tap?(v) }
          else
            val.is_a?(Jazz::Models::Ensemble) && val.name == "Spinal Tap"
          end
        end
      end

      class SingleLoadInputObj < GraphQL::Schema::InputObject
        argument_class BaseArgument
        argument :instrument_id, ID, required: true, loads: Jazz::InstrumentType
      end

      class MultiLoadInputObj < GraphQL::Schema::InputObject
        argument_class BaseArgument
        argument :instrument_ids, [ID], required: true, loads: Jazz::InstrumentType
      end

      class Query < GraphQL::Schema::Object
        field :single_load_input, Jazz::InstrumentType, null: true do
          argument :input, SingleLoadInputObj, required: true
        end
        field :multi_load_input, [Jazz::InstrumentType], null: true do
          argument :input, MultiLoadInputObj, required: true
        end

        def single_load_input(input:)
          input.instrument
        end

        def multi_load_input(input:)
          input.instruments
        end
      end

      class Schema < GraphQL::Schema
        query(Query)

        def self.object_from_id(id, ctx)
          Jazz::GloballyIdentifiableType.find(id)
        end

        def self.resolve_type(type, obj, ctx)
          type
        end

        if TESTING_INTERPRETER
          use GraphQL::Analysis::AST
          use GraphQL::Execution::Interpreter
        end
      end
    end

    let(:single_query_str) {
      <<-GRAPHQL
        query($id: ID!) {
          singleLoadInput(input: {instrumentId: $id}) {
            id
          }
        }
      GRAPHQL
    }

    let(:multi_query_str) {
      <<-GRAPHQL
        query($ids: [ID!]!) {
          multiLoadInput(input: {instrumentIds: $ids}) {
            id
          }
        }
      GRAPHQL
    }

    it "loads arguments as objects of the given type and strips `_id` suffix off argument name" do
      res = InputObjectLoadsTest::Schema.execute(single_query_str, variables: { id: "Ensemble/Robert Glasper Experiment" })
      assert_equal "Ensemble/Robert Glasper Experiment", res["data"]["singleLoadInput"]["id"]
    end

    it "loads arguments as objects of the given type and strips `_ids` suffix off argument name and appends `s`" do
      res = InputObjectLoadsTest::Schema.execute(multi_query_str, variables: { ids: ["Ensemble/Robert Glasper Experiment", "Ensemble/Bela Fleck and the Flecktones"]})
      assert_equal ["Ensemble/Robert Glasper Experiment", "Ensemble/Bela Fleck and the Flecktones"], res["data"]["multiLoadInput"].map { |e| e["id"] }
    end

    it "authorizes based on loaded objects" do
      res = InputObjectLoadsTest::Schema.execute(single_query_str, variables: { id: "Ensemble/Spinal Tap" })
      assert_nil res["data"]["singleLoadInput"]

      res2 = InputObjectLoadsTest::Schema.execute(multi_query_str, variables: { ids: ["Ensemble/Robert Glasper Experiment", "Ensemble/Spinal Tap"]})
      assert_nil res2["data"]["multiLoadInput"]
    end
  end

  describe "in queries" do
    it "is passed to the field method" do
      query_str = <<-GRAPHQL
      {
        inspectInput(input: {
          stringValue: "ABC",
          legacyInput: { intValue: 4 },
          nestedInput: { stringValue: "xyz"},
          ensembleId: "Ensemble/Robert Glasper Experiment"
        })
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str, context: { message: "hi" })
      expected_info = [
        "Jazz::InspectableInput",
        "hi, ABC, 4, (hi, xyz, -, (-))",
        "ABC",
        "ABC",
        "true",
        "ABC",
        Jazz::Models::Ensemble.new("Robert Glasper Experiment").to_s,
        "true",
      ]
      assert_equal expected_info, res["data"]["inspectInput"]
    end

    it "works with given nil values for nested inputs" do
      query_str = <<-GRAPHQL
      query($input: InspectableInput!){
        inspectInput(input: $input)
      }
      GRAPHQL
      input = {
        "nestedInput" => nil,
        "stringValue" => "xyz"
      }
      res = Jazz::Schema.execute(query_str, variables: { input: input }, context: { message: "hi" })
      assert res["data"]["inspectInput"]
    end

    it "uses empty object when no variable value is given" do
      query_str = <<-GRAPHQL
      query($input: InspectableInput){
        inspectInput(input: {
          nestedInput: $input,
          stringValue: "xyz"
        })
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str, variables: { input: nil }, context: { message: "hi" })
      expected_info = [
        "Jazz::InspectableInput",
        "hi, xyz, -, (-)",
        "xyz",
        "xyz",
        "true",
        "xyz",
        "No ensemble",
        "false"
      ]

      assert_equal expected_info, res["data"]["inspectInput"]
    end

    it "handles camelized booleans" do
      res = Jazz::Schema.execute("query($input: CamelizedBooleanInput!){ inputObjectCamelization(input: $input) }", variables: { input: { camelizedBoolean: false } })
      assert_equal "{:camelized_boolean=>false}", res["data"]["inputObjectCamelization"]
    end
  end

  describe "when used with default_value" do
    it "comes as an instance" do
      res = Jazz::Schema.execute("{ defaultValueTest }")
      assert_equal "Jazz::InspectableInput -> {:string_value=>\"S\"}", res["data"]["defaultValueTest"]
    end

    it "works with empty objects" do
      res = Jazz::Schema.execute("{ defaultValueTest2 }")
      assert_equal "Jazz::InspectableInput -> {}", res["data"]["defaultValueTest2"]
    end

    it "introspects in GraphQL language with enums" do
      class InputDefaultSchema < GraphQL::Schema
        class Letter < GraphQL::Schema::Enum
          value "A"
          value "B"
        end

        class InputObj < GraphQL::Schema::InputObject
          argument :a, Letter, required: false
          argument :b, Letter, required: false
        end

        class Query < GraphQL::Schema::Object
          field :i, Int, null: true do
            argument :arg, InputObj, required: false, default_value: { a: "A", b: "B" }
          end
        end

        query(Query)
        use GraphQL::Execution::Interpreter
        use GraphQL::Analysis::AST
      end

      res = InputDefaultSchema.execute "
      {
        __type(name: \"Query\") {
          fields {
            name
            args {
              name
              defaultValue
            }
          }
        }
      }
      "
      assert_equal "{a: A, b: B}", res["data"]["__type"]["fields"].first["args"].first["defaultValue"]
    end
  end

  describe 'hash conversion behavior' do
    module InputObjectToHTest
      class TestInput1 < GraphQL::Schema::InputObject
        graphql_name "TestInput1"
        argument :d, Int, required: true
        argument :e, Int, required: true
        argument :instrument_id, ID, required: true, loads: Jazz::InstrumentType
      end

      class TestInput2 < GraphQL::Schema::InputObject
        graphql_name "TestInput2"
        argument :a, Int, required: true
        argument :b, Int, required: true
        argument :c, TestInput1, as: :inputObject, required: true
      end

      TestInput1.to_graphql
      TestInput2.to_graphql
    end

    before do
      arg_values = {a: 1, b: 2, c: { d: 3, e: 4, instrumentId: "Instrument/Drum Kit"}}

      @input_object = InputObjectToHTest::TestInput2.new(
        arg_values,
        context: OpenStruct.new(warden: Jazz::Schema, schema: Jazz::Schema),
        defaults_used: Set.new
      )
    end

    describe "#to_h" do
      it "returns a symbolized, aliased, ruby keyword style hash" do
        assert_equal({ a: 1, b: 2, input_object: { d: 3, e: 4, instrument: Jazz::Models::Instrument.new("Drum Kit", "PERCUSSION") } }, @input_object.to_h)
      end
    end

    describe "#to_hash" do
      it "returns the same results as #to_h (aliased)" do
        assert_equal(@input_object.to_h, @input_object.to_hash)
      end
    end
  end

  describe "#dig" do
    module InputObjectDigTest
      class TestInput1 < GraphQL::Schema::InputObject
        graphql_name "TestInput1"
        argument :d, Int, required: true
        argument :e, Int, required: true
      end

      class TestInput2 < GraphQL::Schema::InputObject
        graphql_name "TestInput2"
        argument :a, Int, required: true
        argument :b, Int, required: true
        argument :c, TestInput1, as: :inputObject, required: true
      end

      TestInput1.to_graphql
      TestInput2.to_graphql
    end
    arg_values = {a: 1, b: 2, c: { d: 3, e: 4 }}

    input_object = InputObjectDigTest::TestInput2.new(
      arg_values,
      context: nil,
      defaults_used: Set.new
    )
    it "returns the value at that key" do
      assert_equal 1, input_object.dig("a")
      assert_equal 1, input_object.dig(:a)
      assert input_object.dig("inputObject").is_a?(GraphQL::Schema::InputObject)
    end

    it "works with nested keys" do
      assert_equal 3, input_object.dig("inputObject", "d")
      assert_equal 3, input_object.dig(:inputObject, :d)
      assert_equal 3, input_object.dig("inputObject", :d)
      assert_equal 3, input_object.dig(:inputObject, "d")
    end

    it "returns nil for missing keys" do
      assert_nil input_object.dig("z")
      assert_nil input_object.dig(7)
    end

    it "handles underscored keys" do
      # TODO - shouldn't this work too?
      # assert_equal 3, input_object.dig('input_object', 'd')
      assert_equal 3, input_object.dig(:input_object, :d)
    end
  end

  describe "introspection" do
    it "returns input fields" do
      res = Jazz::Schema.execute('
        {
          __type(name: "InspectableInput") {
            name
            inputFields { name }
          }
          __schema {
            types {
              name
              inputFields { name }
            }
          }
        }')
      # Test __type
      assert_equal ["ensembleId", "stringValue", "nestedInput", "legacyInput"], res["data"]["__type"]["inputFields"].map { |f| f["name"] }
      # Test __schema { types }
      # It's upcased to test custom introspection
      input_type = res["data"]["__schema"]["types"].find { |t| t["name"] == "INSPECTABLEINPUT" }
      assert_equal ["ensembleId", "stringValue", "nestedInput", "legacyInput"], input_type["inputFields"].map { |f| f["name"] }
    end
  end

  describe "warning for method objects" do
    it "warns for method conflicts" do
      input_object = Class.new(GraphQL::Schema::InputObject) do
        graphql_name "X"
        argument :method, String, required: true
      end

      expected_warning = "Unable to define a helper for argument with name 'method' as this is a reserved name. Add `method_access: false` to stop this warning.\n"
      assert_output "", expected_warning do
        input_object.graphql_definition
      end
    end

    it "doesn't warn with `method_access: false`" do
      input_object = Class.new(GraphQL::Schema::InputObject) do
        graphql_name "X"
        argument :method, String, required: true, method_access: false
      end

      assert_output "", "" do
        input_object.graphql_definition
      end
    end
  end

  describe "nested objects inside lists" do
    class NestedInputObjectSchema < GraphQL::Schema
      class ItemInput < GraphQL::Schema::InputObject
        argument :str, String, required: true
      end

      class NestedStuff < GraphQL::Schema::RelayClassicMutation
        argument :items, [ItemInput], required: true
        field :str, String, null: false
        def resolve(items:)
          {
            str: items.map { |i| i.class.name }.join(", ")
          }
        end
      end

      class Mutation < GraphQL::Schema::Object
        field :nested_stuff, mutation: NestedStuff
      end

      mutation(Mutation)
      use GraphQL::Analysis::AST
      use GraphQL::Execution::Interpreter
    end

    it "properly wraps them in instances" do
      res = NestedInputObjectSchema.execute "
        mutation($input: NestedStuffInput!) {
          nestedStuff(input: $input) {
            str
          }
        }
      ", variables: { input: { "items" => [{ "str" => "1"}, { "str" => "2"}]}}
      assert_equal "NestedInputObjectSchema::ItemInput, NestedInputObjectSchema::ItemInput", res["data"]["nestedStuff"]["str"]
    end
  end
end
