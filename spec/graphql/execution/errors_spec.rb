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

    use GraphQL::Execution::Interpreter
    use GraphQL::Analysis::AST
    use GraphQL::Execution::Errors

    rescue_from(ErrorA) do |err, obj, args, ctx, field|
      ctx[:errors] << "#{err.message} (#{obj.class.name}.#{field.graphql_name}, #{args.inspect})"
      nil
    end

    rescue_from(ErrorB) do |*|
      raise GraphQL::ExecutionError, "boom!"
    end

    rescue_from(ErrorC) do |err, *|
      err.value
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
        GraphQL::Execution::Lazy.new { raise ErrorA, "f2 broke" }
      end

      field :f3, Int, null: true

      def f3
        raise ErrorB
      end

      field :f4, Int, null: false
      def f4
        raise ErrorC.new(value: 20)
      end

    end

    query(Query)
  end

  describe "rescue_from handling" do
    it "can replace values with `nil`" do
      ctx = { errors: [] }
      res = ErrorsTestSchema.execute "{ f1(a1: 1) }", context: ctx, root_value: :abc
      assert_equal({ "data" => { "f1" => nil } }, res)
      assert_equal ["f1 broke (ErrorsTestSchema::Query.f1, {:a1=>1})"], ctx[:errors]
    end

    it "rescues errors from lazy code" do
      ctx = { errors: [] }
      res = ErrorsTestSchema.execute("{ f2 }", context: ctx)
      assert_equal({ "data" => { "f2" => nil } }, res)
      assert_equal ["f2 broke (ErrorsTestSchema::Query.f2, {})"], ctx[:errors]
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
  end
end
