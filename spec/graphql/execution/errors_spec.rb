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

    class Query < GraphQL::Schema::Object
      field :f_1, Int, null: true do
        argument :a_1, Int, required: false
      end

      def f_1(a_1: nil)
        raise ErrorA, "f_1 broke"
      end

      field :f_2, Int, null: true
      def f_2
        -> { raise ErrorA, "f_2 broke" }
      end

      field :f_3, Int, null: true

      def f_3
        raise ErrorB
      end

      field :f_4, Int, null: false
      def f_4
        raise ErrorC.new(value: 20)
      end

      field :f_5, Int, null: true
      def f_5
        raise ErrorASubclass, "raised subclass"
      end

      field :f_6, Int, null: true
      def f_6
        -> { raise ErrorB }
      end
    end

    query(Query)
    lazy_resolve(Proc, :call)
  end

  describe "rescue_from handling" do
    it "can replace values with `nil`" do
      ctx = { errors: [] }
      res = ErrorsTestSchema.execute "{ f1(a1: 1) }", context: ctx, root_value: :abc
      assert_equal({ "data" => { "f1" => nil } }, res)
      assert_equal ["f_1 broke (ErrorsTestSchema::Query.f1, :abc, {:a_1=>1})"], ctx[:errors]
    end

    it "rescues errors from lazy code" do
      ctx = { errors: [] }
      res = ErrorsTestSchema.execute("{ f2 }", context: ctx)
      assert_equal({ "data" => { "f2" => nil } }, res)
      assert_equal ["f_2 broke (ErrorsTestSchema::Query.f2, nil, {})"], ctx[:errors]
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
  end
end
