# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::MiddlewareChain do
  let(:step_1) { ->(step_values, &next_step) { step_values << 1; next_step.call } }
  let(:step_2) { ->(step_values, &next_step) { step_values << 2; next_step.call } }
  let(:step_3) { ->(step_values, &next_step) { step_values << 3; :return_value } }
  let(:steps) { [step_1, step_2, step_3] }
  let(:step_values) { [] }
  let(:arguments) { [step_values] }
  let(:middleware_chain) { GraphQL::Schema::MiddlewareChain.new(steps: steps)}

  describe "#invoke" do
    it "runs steps in order" do
      middleware_chain.invoke(arguments)
      assert_equal([1,2,3], step_values)
    end

    it "returns the value of the last middleware" do
      assert_equal(:return_value, middleware_chain.invoke(arguments))
    end

    describe "when there is a final step" do
      let(:final_step) { ->(step_values) { step_values << :final; :final_value } }
      let(:middleware_chain) { GraphQL::Schema::MiddlewareChain.new(steps: [step_1, step_2], final_step: final_step) }

      it "calls the final step" do
        middleware_chain.invoke(arguments)
        assert_equal([1, 2, :final], step_values)
      end

      it "returns the value from the final step" do
        assert_equal(:final_value, middleware_chain.invoke(arguments))
      end
    end

    describe "when a step returns early" do
      let(:early_return_step) { ->(step_values, &next_step) { :early_return } }
      it "doesn't continue the chain" do
        steps.insert(2, early_return_step)
        assert_equal(:early_return, middleware_chain.invoke(arguments))
        assert_equal([1,2], step_values)
      end
    end

    describe "when a step provides alternate arguments" do
      it "passes the new arguments to the next step" do
        step_1 = ->(test_arg, &next_step) { assert_equal(test_arg, 'HELLO'); next_step.call(['WORLD']) }
        step_2 = ->(test_arg, &next_step) { assert_equal(test_arg, 'WORLD'); test_arg }

        chain = GraphQL::Schema::MiddlewareChain.new(steps: [step_1, step_2])
        result = chain.invoke(['HELLO'])
        assert_equal(result, 'WORLD')
      end
    end
  end
end
