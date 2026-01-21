# frozen_string_literal: true
require "spec_helper"
require "graphql/execution/next"
describe "Next Execution" do
  class NextExecutionSchema < GraphQL::Schema
    class BaseField < GraphQL::Schema::Field
      def resolve_all(objects, context)
        @all_method_name ||= :"all_#{method_sym}"
        owner.public_send(@all_method_name, objects, context) # TODO args
      end
    end

    class BaseObject < GraphQL::Schema::Object
      field_class BaseField
    end

    class Query < BaseObject
      field :int, Integer

      def self.all_int(objects, context)
        objects.each_with_index.map { |obj, i| i }
      end

      field :str, String

      def self.all_str(objects, context)
        objects.map { |obj| obj.class.name }
      end
    end

    query(Query)
  end


  def run_next(query_str, root_object: nil)
    GraphQL::Execution::Next.run(schema: NextExecutionSchema, query_string: query_str, context: {}, variables: {}, root_object: root_object)
  end

  it "runs a query" do
    result = run_next("{ int str }", root_object: "Abc")
    expected_result = {
      "data" => { "int" => 0, "str" => "String"}
    }
    assert_equal(expected_result, result)
  end
end
