# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::FieldExtension do
  module FilterTestSchema
    class DoubleFilter < GraphQL::Schema::FieldExtension
      def after_resolve(object:, value:, arguments:, context:, memo:)
        value * 2
      end
    end

    class MultiplyByOption < GraphQL::Schema::FieldExtension
      def after_resolve(object:, value:, arguments:, context:, memo:)
        value * options[:factor]
      end
    end

    class MultiplyByArgument < GraphQL::Schema::FieldExtension
      def apply
        field.argument(:factor, Integer, required: true)
      end

      def before_resolve(object:, arguments:, context:)
        factor = arguments.delete(:factor)
        yield(object, arguments, factor)
      end

      def after_resolve(object:, value:, arguments:, context:, memo:)
        value * memo
      end
    end

    class MultiplyByContext < GraphQL::Schema::FieldExtension
      def after_resolve(value:, context:, **_rest)
        if context[:multiply_by]
          value * context[:multiply_by]
        else
          value
        end
      end
    end

    class MultiplyByContextAndOption < GraphQL::Schema::FieldExtension
      def after_resolve(value:, context:, **_rest)
        if context[:multiply_by_context_and_option]
          value * context[:multiply_by_context_and_option] * options[:multiply_by]
        else
          value
        end
      end
    end

    class SuperField < GraphQL::Schema::Field
      extension MultiplyByContext
    end

    class BaseField < SuperField
      extension MultiplyByContextAndOption, multiply_by: 10
    end

    class BaseObject < GraphQL::Schema::Object
      field_class BaseField
    end

    class Query < BaseObject
      field :doubled, Integer, null: false, resolver_method: :pass_thru do
        extension(DoubleFilter)
        argument :input, Integer, required: true
      end

      def pass_thru(input:)
        input # return it as-is, it will be modified by extensions
      end

      field :trippled_by_option, Integer, null: false, resolver_method: :pass_thru do
        extension(MultiplyByOption, factor: 3)
        argument :input, Integer, required: true
      end

      field :multiply_input, Integer, null: false, resolver_method: :pass_thru, extensions: [MultiplyByArgument] do
        argument :input, Integer, required: true
      end
    end

    class Schema < GraphQL::Schema
      query(Query)
      if TESTING_INTERPRETER
        use GraphQL::Execution::Interpreter
      end
    end
  end

  def exec_query(query_str, **kwargs)
    FilterTestSchema::Schema.execute(query_str, **kwargs)
  end

  describe "reading" do
    it "has a reader method" do
      field = FilterTestSchema::Query.fields["multiplyInput"]
      assert_equal 3, field.extensions.size
      assert_instance_of FilterTestSchema::MultiplyByArgument, field.extensions[0]
      assert_instance_of FilterTestSchema::MultiplyByContextAndOption, field.extensions[1]
      assert_instance_of FilterTestSchema::MultiplyByContext, field.extensions[2]
    end
  end

  describe "class-level extensions" do
    it "applies them" do
      query_str = "{ doubled(input: 3) }"
      res = exec_query(query_str)
      assert_equal 6, res["data"]["doubled"], "It can bypass them"

      res2 = exec_query(query_str, context: { multiply_by: 2})
      assert_equal 12, res2["data"]["doubled"], "It can run one of them"

      res3 = exec_query(query_str, context: { multiply_by: 2, multiply_by_context_and_option: 3 })
      assert_equal 360, res3["data"]["doubled"], "It can run both of them"
    end
  end

  describe "modifying return values" do
    it "returns the modified value" do
      res = exec_query("{ doubled(input: 5) }")
      assert_equal 10, res["data"]["doubled"]
    end

    it "has access to config options" do
      # The factor of three came from an option
      res = exec_query("{ trippledByOption(input: 4) }")
      assert_equal 12, res["data"]["trippledByOption"]
    end

    it "can hide arguments from resolve methods" do
      res = exec_query("{ multiplyInput(input: 3, factor: 5) }")
      assert_equal 15, res["data"]["multiplyInput"]
    end
  end
end
