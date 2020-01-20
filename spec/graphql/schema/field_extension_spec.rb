# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::FieldExtension do
  module FilterTestSchema
    class DoubleFilter < GraphQL::Schema::FieldExtension
      def after_resolve(object:, value:, arguments:, context:, memo:)
        value * 2
      end
    end

    class PowerOfFilter < GraphQL::Schema::FieldExtension
      def after_resolve(object:, value:, arguments:, context:, memo:)
        value**options.fetch(:power, 2)
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

      def resolve(object:, arguments:, context:)
        factor = arguments.delete(:factor)
        yield(object, arguments, factor)
      end

      def after_resolve(object:, value:, arguments:, context:, memo:)
        value * memo
      end
    end

    class MultiplyByArgumentUsingResolve < GraphQL::Schema::FieldExtension
      def apply
        field.argument(:factor, Integer, required: true)
      end

      # `yield` returns the user-returned value
      # This method's return value is passed along
      def resolve(object:, arguments:, context:)
        factor = arguments.delete(:factor)
        yield(object, arguments) * factor
      end
    end

    class BaseObject < GraphQL::Schema::Object
    end

    class Query < BaseObject
      field :doubled, Integer, null: false, resolver_method: :pass_thru do
        extension(DoubleFilter)
        argument :input, Integer, required: true
      end

      field :square, Integer, null: false, resolver_method: :pass_thru, extensions: [PowerOfFilter] do
        argument :input, Integer, required: true
      end

      field :cube, Integer, null: false, resolver_method: :pass_thru do
        extension(PowerOfFilter, power: 3)
        argument :input, Integer, required: true
      end

      field :tripled_by_option, Integer, null: false, resolver_method: :pass_thru do
        extension(MultiplyByOption, factor: 3)
        argument :input, Integer, required: true
      end

      field :tripled_by_option2, Integer, null: false, resolver_method: :pass_thru,
        extensions: [{ MultiplyByOption => { factor: 3 } }] do
          argument :input, Integer, required: true
        end

      field :multiply_input, Integer, null: false, resolver_method: :pass_thru, extensions: [MultiplyByArgument] do
        argument :input, Integer, required: true
      end

      field :multiply_input2, Integer, null: false, resolver_method: :pass_thru, extensions: [MultiplyByArgumentUsingResolve] do
        argument :input, Integer, required: true
      end

      def pass_thru(input:, **args)
        input # return it as-is, it will be modified by extensions
      end

      field :multiple_extensions, Integer, null: false, resolver_method: :pass_thru,
        extensions: [DoubleFilter, { MultiplyByOption => { factor: 3 } }] do
          argument :input, Integer, required: true
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

  def exec_query(query_str, **kwargs)
    FilterTestSchema::Schema.execute(query_str, **kwargs)
  end

  describe "reading" do
    it "has a reader method" do
      field = FilterTestSchema::Query.fields["multiplyInput"]
      assert_equal 1, field.extensions.size
      assert_instance_of FilterTestSchema::MultiplyByArgument, field.extensions.first
    end
  end

  describe "modifying return values" do
    it "returns the modified value" do
      res = exec_query("{ doubled(input: 5) }")
      assert_equal 10, res["data"]["doubled"]
    end

    it "returns the modified value from `yield`" do
      res = exec_query("{ multiplyInput2(input: 5, factor: 5) }")
      assert_equal 25, res["data"]["multiplyInput2"]
    end

    it "has access to config options" do
      # The factor of three came from an option
      res = exec_query("{ tripledByOption(input: 4) }")
      assert_equal 12, res["data"]["tripledByOption"]
    end

    it "supports extension with options via extensions kwarg" do
      # The factor of three came from an option
      res = exec_query("{ tripledByOption2(input: 4) }")
      assert_equal 12, res["data"]["tripledByOption2"]
    end

    it "provides an empty hash as default options" do
      res = exec_query("{ square(input: 4) }")
      assert_equal 16, res["data"]["square"]
      res = exec_query("{ cube(input: 4) }")
      assert_equal 64, res["data"]["cube"]
    end

    it "can hide arguments from resolve methods" do
      res = exec_query("{ multiplyInput(input: 3, factor: 5) }")
      assert_equal 15, res["data"]["multiplyInput"]
    end

    it "supports multiple extensions via extensions kwarg" do
      # doubled then multiplied by 3 specified via option
      res = exec_query("{ multipleExtensions(input: 3) }")
      assert_equal 18, res["data"]["multipleExtensions"]
    end
  end
end
