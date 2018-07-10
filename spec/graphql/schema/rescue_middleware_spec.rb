# frozen_string_literal: true
require "spec_helper"

class SpecExampleError < StandardError; end
class SecondSpecExampleError < StandardError; end

describe GraphQL::Schema::RescueMiddleware do
  let(:error_middleware) { ->{ raise(error_class) } }

  let(:rescue_middleware) do
    middleware = GraphQL::Schema::RescueMiddleware.new
    middleware.rescue_from(SpecExampleError) { |err| "there was an example error: #{err.class.name}" }
    middleware
  end

  let(:steps) { [rescue_middleware, error_middleware] }

  let(:middleware_chain) { GraphQL::Schema::MiddlewareChain.new(steps: steps) }

  describe "known errors" do
    let(:error_class) { SpecExampleError }
    it "handles them as execution errors" do
      result = middleware_chain.invoke([])
      assert_equal("there was an example error: SpecExampleError", result.message)
      assert_equal(GraphQL::ExecutionError, result.class)
    end

    describe "rescue_from superclass" do
      class ChildSpecExampleError < SpecExampleError; end

      let(:error_class) { ChildSpecExampleError }
      it "handles them as execution errors" do
        result = middleware_chain.invoke([])
        assert_equal("there was an example error: ChildSpecExampleError", result.message)
        assert_equal(GraphQL::ExecutionError, result.class)
      end
    end

    describe "with multiple error classes" do
      let(:error_class) { SecondSpecExampleError }
      let(:rescue_middleware) do
        middleware = GraphQL::Schema::RescueMiddleware.new
        middleware.rescue_from(SpecExampleError, SecondSpecExampleError) { |err| "there was an example error: #{err.class.name}" }
        middleware
      end

      it "handles errors for all of the classes" do
        result = middleware_chain.invoke([])
        assert_equal("there was an example error: SecondSpecExampleError", result.message)
      end
    end
  end

  describe "unknown errors" do
    let(:error_class) { RuntimeError }
    it "re-raises them" do
      assert_raises(RuntimeError) { middleware_chain.invoke([]) }
    end
  end

  describe "removing multiple error handlers" do
    let(:error_class) { SpecExampleError }
    let(:rescue_middleware) do
      middleware = GraphQL::Schema::RescueMiddleware.new
      middleware.rescue_from(SpecExampleError, SecondSpecExampleError) { |err| "there was an example error: #{err.class.name}" }
      middleware.remove_handler(SpecExampleError, SecondSpecExampleError)
      middleware
    end

    it "no longer handles those errors" do
      assert_raises(SpecExampleError) { middleware_chain.invoke([]) }
    end
  end
end
