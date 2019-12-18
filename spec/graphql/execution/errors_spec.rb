# frozen_string_literal: true
require "spec_helper"

describe "GraphQL::Execution::Errors" do
  class ErrorsTestSchema < GraphQL::Schema
    class ErrorA < RuntimeError; end
    class ErrorB < RuntimeError; end
    class ErrorC < RuntimeError
      attr_reader :value
      def initialize(value:)
        @value = value
        super
      end
    end
    class ErrorD < RuntimeError; end

    class ErrorASubclass < ErrorA; end

    use GraphQL::Execution::Interpreter
    use GraphQL::Analysis::AST
    use GraphQL::Execution::Errors

    rescue_from(ErrorA) do |err, obj, args, ctx, field|
      ctx[:errors] << "#{err.message} (#{field.owner.name}.#{field.graphql_name}, #{obj.inspect}, #{args.inspect})"
      nil
    end

    rescue_from(ErrorB) do |*|
      raise GraphQL::ExecutionError, "boom!"
    end

    rescue_from(ErrorC) do |err, *|
      err.value
    end

    rescue_from(ErrorD) do |err, obj, args, ctx, field|
      raise GraphQL::ExecutionError, "ErrorD on #{obj.inspect} at #{field ? "#{field.path}(#{args})" : "boot"}"
    end

    class Thing < GraphQL::Schema::Object
      def self.authorized?(obj, ctx)
        if ctx[:authorized] == false
          raise ErrorD
        end
      end

      field :string, String, null: false
      def string
        "a string"
      end
    end

    class ValuesInput < GraphQL::Schema::InputObject
      argument :value, Int, required: true, loads: Thing

      def object_from_id(type, value, ctx)
        if value == 1
          :thing
        else
          raise ErrorD
        end
      end
    end

    class Query < GraphQL::Schema::Object
      field :f1, Int, null: true do
        argument :a1, Int, required: false
      end

      def f1(a1: nil)
        raise ErrorA, "f1 broke"
      end

      field :f2, Int, null: true
      def f2
        -> { raise ErrorA, "f2 broke" }
      end

      field :f3, Int, null: true

      def f3
        raise ErrorB
      end

      field :f4, Int, null: false
      def f4
        raise ErrorC.new(value: 20)
      end

      field :f5, Int, null: true
      def f5
        raise ErrorASubclass, "raised subclass"
      end

      field :f6, Int, null: true
      def f6
        -> { raise ErrorB }
      end

      field :thing, Thing, null: true
      def thing
        :thing
      end

      field :input_field, Int, null: true do
        argument :values, ValuesInput, required: true, method_access: false
      end

      field :non_nullable_array, [String], null: false
      def non_nullable_array
        [nil]
      end
    end

    query(Query)
    lazy_resolve(Proc, :call)
  end

  class ErrorsTestSchemaWithoutInterpreter < GraphQL::Schema
    class Query < GraphQL::Schema::Object
      field :non_nullable_array, [String], null: false
      def non_nullable_array
        [nil]
      end
    end

    query(Query)
  end

  describe "rescue_from handling" do
    it "can replace values with `nil`" do
      ctx = { errors: [] }
      res = ErrorsTestSchema.execute "{ f1(a1: 1) }", context: ctx, root_value: :abc
      assert_equal({ "data" => { "f1" => nil } }, res)
      assert_equal ["f1 broke (ErrorsTestSchema::Query.f1, :abc, {:a1=>1})"], ctx[:errors]
    end

    it "rescues errors from lazy code" do
      ctx = { errors: [] }
      res = ErrorsTestSchema.execute("{ f2 }", context: ctx)
      assert_equal({ "data" => { "f2" => nil } }, res)
      assert_equal ["f2 broke (ErrorsTestSchema::Query.f2, nil, {})"], ctx[:errors]
    end

    it "rescues errors from lazy code with handlers that re-raise" do
      res = ErrorsTestSchema.execute("{ f6 }")
      expected_error = {
        "message"=>"boom!",
        "locations"=>[{"line"=>1, "column"=>3}],
        "path"=>["f6"]
      }
      assert_equal({ "data" => { "f6" => nil }, "errors" => [expected_error] }, res)
    end

    it "can raise new errors" do
      res = ErrorsTestSchema.execute("{ f3 }")
      expected_error = {
        "message"=>"boom!",
        "locations"=>[{"line"=>1, "column"=>3}],
        "path"=>["f3"]
      }
      assert_equal({ "data" => { "f3" => nil }, "errors" => [expected_error] }, res)
    end

    it "can replace values with non-nil" do
      res = ErrorsTestSchema.execute("{ f4 }")
      assert_equal({ "data" => { "f4" => 20 } }, res)
    end

    it "rescues subclasses" do
      context = { errors: [] }
      res = ErrorsTestSchema.execute("{ f5 }", context: context)
      assert_equal({ "data" => { "f5" => nil } }, res)
      assert_equal ["raised subclass (ErrorsTestSchema::Query.f5, nil, {})"], context[:errors]
    end

    describe "errors raised in authorized hooks" do
      it "rescues them" do
        context = { authorized: false }
        res = ErrorsTestSchema.execute(" { thing { string } } ", context: context)
        assert_equal ["ErrorD on nil at Query.thing({})"], res["errors"].map { |e| e["message"] }
      end
    end

    describe "errors raised in input_object loads" do
      it "rescues them from literal values" do
        context = { authorized: false }
        res = ErrorsTestSchema.execute(" { inputField(values: { value: 2 }) } ", root_value: :root, context: context)
        # It would be better to have the arguments here, but since this error was raised during _creation_ of keywords,
        # so the runtime arguments aren't available now.
        assert_equal ["ErrorD on :root at Query.inputField()"], res["errors"].map { |e| e["message"] }
      end

      it "rescues them from variable values" do
        context = { authorized: false }
        res = ErrorsTestSchema.execute(
          "query($values: ValuesInput!) { inputField(values: $values) } ",
          variables: { values: { value: 2 } },
          context: context,
        )
        # The message appears in extensions here:
        assert_equal ["ErrorD on nil at boot"], res["errors"].map { |e| e["extensions"]["problems"][0]["explanation"] }
      end
    end

    describe "errors raised in non_nullable_array loads" do
      it "outputs the appropriate error message when using non-interpreter schema" do
        res = ErrorsTestSchemaWithoutInterpreter.execute("{ nonNullableArray }")
        expected_error = {
          "message" => "Cannot return null for non-nullable field Query.nonNullableArray"
        }
        assert_equal({ "data" => nil, "errors" => [expected_error] }, res)
      end

      it "outputs the appropriate error message when using interpreter schema" do
        res = ErrorsTestSchema.execute("{ nonNullableArray }")
        expected_error = {
          "message" => "Cannot return null for non-nullable field Query.nonNullableArray"
        }
        assert_equal({ "data" => nil, "errors" => [expected_error] }, res)
      end
    end
  end
end
