require "spec_helper"

class SpecExampleError < StandardError; end

describe GraphQL::Schema::RescueMiddleware do
  let(:error_middleware) { -> (next_middleware) { raise(error_class) } }

  let(:rescue_middleware) do
    middleware = GraphQL::Schema::RescueMiddleware.new
    middleware.rescue_from(SpecExampleError) { |err| "there was an example error: #{err.class.name}" }
    middleware
  end

  let(:steps) { [rescue_middleware, error_middleware] }

  let(:middleware_chain) { GraphQL::Schema::MiddlewareChain.new(steps: steps, arguments: [])}

  describe "known errors" do
    let(:error_class) { SpecExampleError }
    it "handles them as execution errors" do
      result = middleware_chain.call
      assert_equal("there was an example error: SpecExampleError", result.message)
      assert_equal(GraphQL::ExecutionError, result.class)
    end
  end

  describe "unknown errors" do
    let(:error_class) { RuntimeError }
    it "re-raises them" do
      assert_raises(RuntimeError) { middleware_chain.call }
    end
  end
end
