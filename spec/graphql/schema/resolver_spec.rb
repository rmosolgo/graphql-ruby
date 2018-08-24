# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Resolver do
  module ResolverTest
    class LazyBlock
      def initialize
        @get_value = Proc.new
      end

      def value
        @get_value.call
      end
    end

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
    end

    class Resolver4 < BaseResolver
      type Integer, null: false

      extras [:ast_node]

      def resolve(ast_node:)
        object.value + ast_node.name.size
      end
    end

    class Resolver5 < Resolver4
    end

    class Resolver6 < Resolver1
      type Integer, null: false

      def resolve
        self.class.complexity
      end
    end

    class Resolver7 < Resolver6
      complexity 2
    end

    class Resolver8 < Resolver7
    end

    class PrepResolver1 < BaseResolver
      argument :int, Integer, required: true
      undef_method :load_int

      def load_int(i)
        i * 10
      end

      type Integer, null: false

      def resolve(int:)
        int
      end

      private

      def check_for_magic_number(int)
        if int == 13
          raise GraphQL::ExecutionError, "13 is unlucky!"
        elsif int > 99
          raise GraphQL::UnauthorizedError, "Top secret big number: #{int}"
        else
          int
        end
      end
    end

    class PrepResolver2 < PrepResolver1
      def load_int(i)
        LazyBlock.new {
          super - 35
        }
      end
    end

    class PrepResolver3 < PrepResolver1
      type Integer, null: true

      def load_int(i)
        check_for_magic_number(i)
      end
    end

    class PrepResolver4 < PrepResolver3
      def load_int(i)
        LazyBlock.new {
          super
        }
      end
    end

    class PrepResolver5 < PrepResolver1
      type Integer, null: true

      def ready?(int:)
        check_for_magic_number(int)
      end
    end

    class PrepResolver6 < PrepResolver5
      def ready?(**args)
        LazyBlock.new {
          super
        }
      end
    end

    class PrepResolver7 < GraphQL::Schema::Mutation
      argument :int, Integer, required: true
      field :errors, [String], null: true
      field :int, Integer, null: true

      def ready?(int:)
        if int == 13
          return false, {errors: ["Bad number!"]}
        else
          true
        end
      end

      def resolve(int:)
        {int: int}
      end
    end

    module HasValue
      include GraphQL::Schema::Interface
      field :value, Integer, null: false
      def self.resolve_type(obj, ctx)
        if obj.is_a?(Integer)
          IntegerWrapper
        else
          raise "Unexpected: #{obj.inspect}"
        end
      end
    end

    class IntegerWrapper < GraphQL::Schema::Object
      implements HasValue
      field :value, Integer, null: false, method: :object
    end

    class PrepResolver9 < BaseResolver
      argument :int_id, ID, required: true, loads: HasValue
      # Make sure the lazy object is resolved properly:
      type HasValue, null: false

      def object_from_id(type, id, ctx)
        # Make sure a lazy object is handled appropriately
        LazyBlock.new {
          # Make sure that the right type ends up here
          id.to_i + type.graphql_name.length
        }
      end

      def resolve(int:)
        int * 3
      end
    end

    class PrepResolver10 < BaseResolver
      argument :int1, Integer, required: true
      argument :int2, Integer, required: true, as: :integer_2
      type Integer, null: true

      def authorized?(int1:, integer_2:)
        if int1 + integer_2 > context[:max_int]
          raise GraphQL::ExecutionError, "Inputs too big"
        elsif context[:min_int] && (int1 + integer_2 < context[:min_int])
          false
        else
          true
        end
      end

      def resolve(int1:, integer_2:)
        int1 + integer_2
      end
    end

    class PrepResolver11 < PrepResolver10
      def authorized?(int1:, integer_2:)
        LazyBlock.new { super(int1: int1 * 2, integer_2: integer_2) }
      end
    end

    class PrepResolver12 < GraphQL::Schema::Mutation
      argument :int1, Integer, required: true
      argument :int2, Integer, required: true
      field :error_messages, [String], null: true
      field :value, Integer, null: true

      def authorized?(int1:, int2:)
        if int1 + int2 > context[:max_int]
          return false, {error_messages: ["Inputs must be less than #{context[:max_int]} (but you provided #{int1 + int2})"]}
        else
          true
        end
      end

      def resolve(int1:, int2:)
        {value: int1 + int2}
      end
    end

    class PrepResolver13 < PrepResolver12
      def authorized?(int1:, int2:)
        # Increment the numbers so we can be sure they're passing through here
        LazyBlock.new { super(int1: int1 + 1, int2: int2 + 1) }
      end
    end

    class PrepResolver14 < GraphQL::Schema::RelayClassicMutation
      field :number, Integer, null: false

      def authorized?
        true
      end

      def resolve
        {number: 1}
      end
    end

    class Query < GraphQL::Schema::Object
      class CustomField < GraphQL::Schema::Field
        def resolve_field(*args)
          value = super
          if @name == "resolver3"
            value << -1
          end
          value
        end
      end

      field_class(CustomField)

      field :resolver_1, resolver: Resolver1
      field :resolver_2, resolver: Resolver2
      field :resolver_3, resolver: Resolver3
      field :resolver_3_again, resolver: Resolver3, description: "field desc"
      field :resolver_4, "Positional description", resolver: Resolver4
      field :resolver_5, resolver: Resolver5
      field :resolver_6, resolver: Resolver6
      field :resolver_7, resolver: Resolver7
      field :resolver_8, resolver: Resolver8

      field :prep_resolver_1, resolver: PrepResolver1
      field :prep_resolver_2, resolver: PrepResolver2
      field :prep_resolver_3, resolver: PrepResolver3
      field :prep_resolver_4, resolver: PrepResolver4
      field :prep_resolver_5, resolver: PrepResolver5
      field :prep_resolver_6, resolver: PrepResolver6
      field :prep_resolver_7, resolver: PrepResolver7
      field :prep_resolver_9, resolver: PrepResolver9
      field :prep_resolver_10, resolver: PrepResolver10
      field :prep_resolver_11, resolver: PrepResolver11
      field :prep_resolver_12, resolver: PrepResolver12
      field :prep_resolver_13, resolver: PrepResolver13
      field :prep_resolver_14, resolver: PrepResolver14
    end

    class Schema < GraphQL::Schema
      query(Query)
      lazy_resolve LazyBlock, :value
      orphan_types IntegerWrapper
    end
  end

  def exec_query(*args)
    ResolverTest::Schema.execute(*args)
  end

  describe ".path" do
    it "is the name" do
      assert_equal "Resolver1", ResolverTest::Resolver1.path
    end

    it "is used for arguments and fields" do
      assert_equal "Resolver1.value", ResolverTest::Resolver1.arguments["value"].path
      assert_equal "PrepResolver7.int", ResolverTest::PrepResolver7.fields["int"].path
    end

    it "works on instances" do
      r = ResolverTest::Resolver1.new(object: nil, context: nil)
      assert_equal "Resolver1", r.path
    end
  end

  it "gets initialized for each resolution" do
    # State isn't shared between calls:
    res = exec_query " { r1: resolver1(value: 1) r2: resolver1 }"
    assert_equal [100, 1], res["data"]["r1"]
    assert_equal [100, nil], res["data"]["r2"]
  end

  it "inherits type and arguments" do
    res = exec_query " { r1: resolver2(value: 1, extraValue: 2) r2: resolver2(extraValue: 3) }"
    assert_equal [100, 1, 2], res["data"]["r1"]
    assert_equal [100, nil, 3], res["data"]["r2"]
  end

  it "uses the object's field_class" do
    res = exec_query " { r1: resolver3(value: 1) r2: resolver3 }"
    assert_equal [100, 1, -1], res["data"]["r1"]
    assert_equal [100, nil, -1], res["data"]["r2"]
  end

  describe "resolve method" do
    it "has access to the application object" do
      res = exec_query " { resolver4 } ", root_value: OpenStruct.new(value: 4)
      assert_equal 13, res["data"]["resolver4"]
    end

    it "gets extras" do
      res = exec_query " { resolver4 } ", root_value: OpenStruct.new(value: 0)
      assert_equal 9, res["data"]["resolver4"]
    end
  end

  describe "extras" do
    it "is inherited" do
      res = exec_query " { resolver4 resolver5 } ", root_value: OpenStruct.new(value: 0)
      assert_equal 9, res["data"]["resolver4"]
      assert_equal 9, res["data"]["resolver5"]
    end
  end

  describe "complexity" do
    it "has default values" do
      res = exec_query " { resolver6 } ", root_value: OpenStruct.new(value: 0)
      assert_equal 1, res["data"]["resolver6"]
    end

    it "is inherited" do
      res = exec_query " { resolver7 resolver8 } ", root_value: OpenStruct.new(value: 0)
      assert_equal 2, res["data"]["resolver7"]
      assert_equal 2, res["data"]["resolver8"]
    end
  end

  describe "when applied to a field" do
    it "gets the field's description" do
      assert_nil ResolverTest::Schema.find("Query.resolver3").description
      assert_equal "field desc", ResolverTest::Schema.find("Query.resolver3Again").description
      assert_equal "Positional description", ResolverTest::Schema.find("Query.resolver4").description
    end

    it "gets the field's name" do
      # Matching name:
      assert ResolverTest::Schema.find("Query.resolver3")
      # Mismatched name:
      assert ResolverTest::Schema.find("Query.resolver3Again")
    end
  end

  describe "preparing inputs" do
    # Add assertions for a given field, assuming the behavior of `check_for_magic_number`
    def add_error_assertions(field_name, description)
      res = exec_query("{ int: #{field_name}(int: 13) }")
      assert_nil res["data"].fetch("int"), "#{description}: no result for execution error"
      assert_equal ["13 is unlucky!"], res["errors"].map { |e| e["message"] }, "#{description}: top-level error is added"

      res = exec_query("{ int: #{field_name}(int: 200) }")
      assert_nil res["data"].fetch("int"), "#{description}: No result for authorization error"
      refute res.key?("errors"), "#{description}: silent auth failure (no top-level error)"
    end

    describe "ready?" do
      it "can raise errors" do
        res = exec_query("{ int: prepResolver5(int: 5) }")
        assert_equal 50, res["data"]["int"]
        add_error_assertions("prepResolver5", "ready?")
      end

      it "can raise errors in lazy sync" do
        res = exec_query("{ int: prepResolver6(int: 5) }")
        assert_equal 50, res["data"]["int"]
        add_error_assertions("prepResolver6", "lazy ready?")
      end

      it "can return false and data" do
        res = exec_query("{ int: prepResolver7(int: 13) { errors int } }")
        assert_equal ["Bad number!"], res["data"]["int"]["errors"]

        res = exec_query("{ int: prepResolver7(int: 213) { errors int } }")
        assert_equal 213, res["data"]["int"]["int"]
      end
    end

    describe "loading arguments" do
      it "calls load methods and injects the return value" do
        res = exec_query("{ prepResolver1(int: 5) }")
        assert_equal 50, res["data"]["prepResolver1"], "The load multiplier was called"
      end

      it "supports lazy values" do
        res = exec_query("{ prepResolver2(int: 5) }")
        assert_equal 15, res["data"]["prepResolver2"], "The load multiplier was called"
      end

      it "supports raising GraphQL::UnauthorizedError and GraphQL::ExecutionError" do
        res = exec_query("{ prepResolver3(int: 5) }")
        assert_equal 5, res["data"]["prepResolver3"]
        add_error_assertions("prepResolver3", "load_ hook")
      end

      it "supports raising errors from promises" do
        res = exec_query("{ prepResolver4(int: 5) }")
        assert_equal 5, res["data"]["prepResolver4"]
        add_error_assertions("prepResolver4", "lazy load_ hook")
      end
    end

    describe "validating arguments" do
      describe ".authorized?" do
        it "can raise an error to halt" do
          res = exec_query("{ prepResolver10(int1: 5, int2: 6) }", context: {max_int: 9})
          assert_equal ["Inputs too big"], res["errors"].map { |e| e["message"] }

          res = exec_query("{ prepResolver10(int1: 5, int2: 6) }", context: {max_int: 90})
          assert_equal 11, res["data"]["prepResolver10"]
        end

        it "uses the argument name provided in `as:`" do
          res = exec_query("{ prepResolver10(int1: 5, int2: 6) }", context: {max_int: 90})
          assert_equal 11, res["data"]["prepResolver10"]
        end

        it "can return a lazy object" do
          # This is too big because it's modified in the overridden authorized? hook:
          res = exec_query("{ prepResolver11(int1: 3, int2: 5) }", context: {max_int: 9})
          assert_equal ["Inputs too big"], res["errors"].map { |e| e["message"] }

          res = exec_query("{ prepResolver11(int1: 3, int2: 5) }", context: {max_int: 90})
          assert_equal 8, res["data"]["prepResolver11"]
        end

        it "can return data early" do
          res = exec_query("{ prepResolver12(int1: 9, int2: 5) { errorMessages } }", context: {max_int: 9})
          assert_equal ["Inputs must be less than 9 (but you provided 14)"], res["data"]["prepResolver12"]["errorMessages"]
          # This works
          res = exec_query("{ prepResolver12(int1: 2, int2: 5) { value } }", context: {max_int: 9})
          assert_equal 7, res["data"]["prepResolver12"]["value"]
        end

        it "can return data early in a promise" do
          # This is too big because it's modified in the overridden authorized? hook:
          res = exec_query("{ prepResolver13(int1: 4, int2: 4) { errorMessages } }", context: {max_int: 9})
          assert_equal ["Inputs must be less than 9 (but you provided 10)"], res["data"]["prepResolver13"]["errorMessages"]
          # This works
          res = exec_query("{ prepResolver13(int1: 2, int2: 5) { value } }", context: {max_int: 9})
          assert_equal 7, res["data"]["prepResolver13"]["value"]
        end

        it "can return false to halt" do
          str = <<-GRAPHQL
          {
            prepResolver10(int1: 5, int2: 10)
            prepResolver11(int1: 3, int2: 5)
          }
          GRAPHQL
          res = exec_query(str, context: {max_int: 100, min_int: 20})
          assert_equal({"prepResolver10" => nil, "prepResolver11" => nil}, res["data"])
        end

        it "works with no arguments for RelayClassicMutation" do
          res = exec_query("{ prepResolver14(input: {}) { number } }")
          assert_equal 1, res["data"]["prepResolver14"]["number"]
        end
      end
    end

    describe "Loading inputs" do
      it "calls object_from_id" do
        res = exec_query('{ prepResolver9(intId: "5") { value } }')
        # (5 + 8) * 3
        assert_equal 39, res["data"]["prepResolver9"]["value"]
      end
    end
  end
end
