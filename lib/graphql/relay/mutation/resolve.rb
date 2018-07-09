# frozen_string_literal: true
module GraphQL
  module Relay
    class Mutation
      # Wrap a user-provided resolve function,
      # wrapping the returned value in a {Mutation::Result}.
      # Also, pass the `clientMutationId` to that result object.
      # @api private
      class Resolve
        def initialize(mutation, resolve)
          @mutation = mutation
          @resolve = resolve
          @wrap_result = mutation.is_a?(GraphQL::Relay::Mutation) && mutation.has_generated_return_type?
          @class_based = mutation.is_a?(Class)
        end

        def call(obj, args, ctx)
          mutation_result = begin
            @resolve.call(obj, args[:input], ctx)
          rescue GraphQL::ExecutionError => err
            err
          end

          ctx.schema.after_lazy(mutation_result) do |res|
            build_result(res, args, ctx)
          end
        end

        private

        def build_result(mutation_result, args, ctx)
          if mutation_result.is_a?(GraphQL::ExecutionError)
            ctx.add_error(mutation_result)
            mutation_result = nil
          end

          if mutation_result.nil?
            nil
          elsif @wrap_result
            if mutation_result && !mutation_result.is_a?(Hash)
              raise StandardError, "Expected `#{mutation_result}` to be a Hash."\
                " Return a hash when using `return_field` or specify a custom `return_type`."
            end

            @mutation.result_class.new(client_mutation_id: args[:input][:clientMutationId], result: mutation_result)
          elsif @class_based
            mutation_result[:client_mutation_id] = args[:input][:client_mutation_id]
            mutation_result
          else
            mutation_result
          end
        end
      end
    end
  end
end
