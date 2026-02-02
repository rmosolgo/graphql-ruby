# frozen_string_literal: true
module GraphQL
  module Execution
    module Batching
      class SelectionsStep
        def initialize(parent_type:, selections:, objects:, results:, runner:, path:)
          @path = path
          @parent_type = parent_type
          @selections = selections
          @runner = runner
          @objects = objects
          @results = results
          @graphql_objects = nil
        end

        attr_reader :path

        def graphql_objects
          @graphql_objects ||= @objects.map do |obj|
            @parent_type.scoped_new(obj, @runner.context)
          end
        end

        def call
          grouped_selections = {}
          prototype_result = @results.first
          @runner.gather_selections(@parent_type, @selections, self, prototype_result, into: grouped_selections)
          @results.each { |r| r.replace(prototype_result) }
          grouped_selections.each_value do |frs|
            frs.objects = @objects
            frs.results = @results
            @runner.add_step(frs)
          end
        end
      end
    end
  end
end
