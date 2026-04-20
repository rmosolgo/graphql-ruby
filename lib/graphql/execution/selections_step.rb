# frozen_string_literal: true
module GraphQL
  module Execution
    class SelectionsStep
      def initialize(parent_type:, selections:, objects:, results:, runner:, query:, path:, clobber: true)
        @path = path
        @parent_type = parent_type
        @selections = selections
        @runner = runner
        @objects = objects
        @results = results
        @query = query
        @graphql_objects = nil
        @all_selections = nil
        @clobber = clobber
      end

      attr_reader :path, :query, :objects, :results

      def graphql_objects
        @graphql_objects ||= @objects.map do |obj|
          @parent_type.scoped_new(obj, @query.context)
        end
      end

      def call
        @all_selections = [{}, (prototype_result = {})]
        @runner.gather_selections(@parent_type, @selections, self, self.query, @all_selections, @all_selections[1], into: @all_selections[0])
        continue_selections = []
        i = 0
        l = @all_selections.length
        while i < l
          grouped_selections = @all_selections[i]
          selections_prototype_result = @all_selections[i + 1]
          if (directives_owner = grouped_selections.delete(:__node))
            directives = directives_owner.directives
            continue_execution = true
            directives.each do |dir_node|
              dir_defn = @runner.runtime_directives[dir_node.name]
              if dir_defn # not present for `skip` or `include`
                dummy_frs = FieldResolveStep.new(
                  selections_step: self,
                  key: nil,
                  parent_type: @parent_type,
                  runner: @runner,
                )
                dir_args = dummy_frs.coerce_arguments(dir_defn, dir_node.arguments, false) # rubocop:disable Development/ContextIsPassedCop
                result = case directives_owner
                when Language::Nodes::FragmentSpread
                  dir_defn.resolve_fragment_spread(directives_owner, @parent_type, @objects, dir_args, self.query.context)
                when Language::Nodes::InlineFragment
                  dir_defn.resolve_inline_fragment(directives_owner, @parent_type, @objects, dir_args, self.query.context)
                else
                  raise ArgumentError, "Unhandled directive owner (#{directives_owner.class}): #{directives_owner.inspect}"
                end
                if result.is_a?(Finalizer)
                  result.path = path
                  @results.each do |r|
                    @runner.add_finalizer(@query, r, nil, result)
                  end
                  if result.is_a?(HaltExecution)
                    continue_execution = false
                    break
                  end
                end

                if continue_execution
                  prototype_result.merge!(selections_prototype_result)
                  grouped_selections.each_value { |v| continue_selections << v }
                end
              else
                grouped_selections.each_value { |v| continue_selections << v }
              end
            end
          else
            grouped_selections.each_value { |v| continue_selections << v }
          end

          if @clobber
            i2 = 0
            l2 = @results.length
            while i2 < l2
              @results[i2].replace(prototype_result)
              i2 += 1
            end
          end

          continue_selections.each do |frs|
            @runner.add_step(frs)
          end

          i += 2
        end
      end
    end
  end
end
