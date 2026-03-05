# frozen_string_literal: true
module GraphQL
  module Execution
    module Batching
      class ResolversStep
        def initialize(field_resolve_step:, resolvers:)
          @field_resolve_step = field_resolve_step
          @resolvers = resolvers
          @finished_resolvers = nil
        end

        def call
          if @finished_resolvers.nil?
            @resolvers.each do |r|
              r.resolvers_step = self
              @field_resolve_step.runner.add_step(r)
            end
          end
        end

        attr_reader :field_resolve_step
      end
    end
  end
end
