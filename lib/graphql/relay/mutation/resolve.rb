# frozen_string_literal: true
module GraphQL
  module Relay
    class Mutation
      # Wrap a user-provided resolve function,
      # wrapping the returned value in a {Mutation::Result}.
      # Also, pass the `clientMutationId` to that result object.
      # @api private
      class Resolve
        def initialize(mutation, resolve, eager:)
          @mutation = mutation
          @resolve = resolve
          @wrap_result = mutation.has_generated_return_type?
          @eager = eager
        end

        def call(obj, args, ctx)
          error_raised = false
          begin
            mutation_result = @resolve.call(obj, args[:input], ctx)
          rescue GraphQL::ExecutionError => err
            mutation_result = err
            error_raised = true
          end

          if ctx.schema.lazy?(mutation_result)
            mutation_result
          else
            build_result(mutation_result, args, ctx, raised: error_raised)
          end
        end

        private

        def build_result(mutation_result, args, ctx, raised: false)
          if mutation_result.is_a?(GraphQL::ExecutionError)
            ctx.add_error(mutation_result)
            mutation_result = nil
          end

          if @eager && raised
            nil
          elsif @wrap_result
            if mutation_result && !mutation_result.is_a?(Hash)
              raise StandardError, "Expected `#{mutation_result}` to be a Hash."\
                " Return a hash when using `return_field` or specify a custom `return_type`."
            end

            @mutation.result_class.new(client_mutation_id: args[:input][:clientMutationId], result: mutation_result)
          else
            mutation_result
          end
        end
      end
    end
  end
end
