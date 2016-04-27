require "spec_helper"

describe GraphQL::Schema::MiddlewareChain do
  let(:step_1) { -> (step_values, next_step) { step_values << 1; next_step.call } }
  let(:step_2) { -> (step_values, next_step) { step_values << 2; next_step.call } }
  let(:step_3) { -> (step_values, next_step) { step_values << 3; :return_value } }
  let(:steps) { [step_1, step_2, step_3] }
  let(:step_values) { [] }
  let(:arguments) { [step_values] }
  let(:middleware_chain) { GraphQL::Schema::MiddlewareChain.new(steps: steps, arguments: arguments)}

  describe "#call" do
    it "runs steps in order" do
      middleware_chain.call
      assert_equal([1,2,3], step_values)
    end

    it "returns the value of the last middleware" do
      assert_equal(:return_value, middleware_chain.call)
    end

    describe "when a step returns early" do
      let(:early_return_step) { -> (step_values, next_step) { :early_return } }
      it "doesn't continue the chain" do
        steps.insert(2, early_return_step)
        assert_equal(:early_return, middleware_chain.call)
        assert_equal([1,2], step_values)
      end
    end
  end
end
