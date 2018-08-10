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
      def initialize(field:, options:)
        field.argument(:factor, Integer, required: true)
        super
      end

      def before_resolve(object:, arguments:, context:)
        factor = arguments.delete(:factor)
        yield(object, arguments, factor)
      end

      def after_resolve(object:, value:, arguments:, context:, memo:)
        value * memo
      end
    end

    class BaseObject < GraphQL::Schema::Object
    end

    class Query < BaseObject
      field :doubled, Integer, null: false, method: :pass_thru do
        extension(DoubleFilter)
        argument :input, Integer, required: true
      end

      def pass_thru(input:)
        input # return it as-is, it will be modified by extensions
      end

      field :trippled_by_option, Integer, null: false, method: :pass_thru do
        extension(MultiplyByOption, factor: 3)
        argument :input, Integer, required: true
      end

      field :multiply_input, Integer, null: false, method: :pass_thru, extensions: [MultiplyByArgument] do
        argument :input, Integer, required: true
      end
    end

    class Schema < GraphQL::Schema
      query(Query)
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
