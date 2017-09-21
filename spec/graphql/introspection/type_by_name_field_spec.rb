# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Introspection::TypeByNameField do
  describe "after instrumentation" do
    # Just make sure it returns a new object, not the original field
    class DupInstrumenter
      def self.instrument(t, f)
        f.redefine {
          resolve ->(o, a, c) { :no_op }
        }
      end
    end

    class ArgAnalyzer
      def call(_, _, node)
        if node.ast_node.is_a?(GraphQL::Language::Nodes::Field)
          node.arguments
        end
      end
    end

    let(:instrumented_schema) {
      # This was probably assigned earlier in the test suite, but to simulate an application, clear it.
      GraphQL::Introspection::TypeByNameField.arguments_class = nil

      Dummy::Schema.redefine {
        instrument(:field, DupInstrumenter)
        query_analyzer(ArgAnalyzer.new)
      }
    }

    it "still works with __type" do
      res = instrumented_schema.execute("{ __type(name: \"X\") { name } }")
      assert_equal({"data"=>{"__type"=>nil}}, res)
    end
  end
end
